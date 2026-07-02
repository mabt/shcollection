#!/usr/bin/env python3
"""Pilote la VM de test archi3 : tape le curl|bash sur tty1 (via monitor
QEMU), puis répond aux prompts par console série et vérifie l'install.
Logs : driver.log (déroulé), serial.log (console brute), status.txt (état)."""
import os, re, socket, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
MON = ("127.0.0.1", 5556)
SER = ("127.0.0.1", 5555)
PASSWORD = "test123"
# ARCHSWAY_URL : http://10.0.2.2:8000 (défaut, serveur local) ou l'URL
# raw.githubusercontent pour tester le vrai flux (pas d'override RAW_URL alors)
BASE = os.environ.get("ARCHSWAY_URL", "http://10.0.2.2:8000")
OVERRIDE = "" if "github" in BASE else "RAW_URL=%s " % BASE
CURL_CMD = ("curl -fsSL %s/archsway-1-base.sh -o /root/a.sh && %sbash /root/a.sh"
            % (BASE, OVERRIDE))
DEADLINE = time.time() + 100 * 60          # 100 min max au total

logf = open(os.path.join(HERE, "driver.log"), "a", buffering=1)
serf = open(os.path.join(HERE, "serial.log"), "ab", buffering=0)

def log(msg):
    line = time.strftime("[%H:%M:%S] ") + msg
    print(line, flush=True); logf.write(line + "\n")

def status(s):
    with open(os.path.join(HERE, "status.txt"), "w") as f: f.write(s + "\n")
    log("STATUS: " + s)

def die(reason):
    status("FAIL: " + reason); sys.exit(1)

# ---------------- monitor QEMU (sendkey) ----------------
SPECIAL = {' ': 'spc', '-': 'minus', '=': 'equal', '.': 'dot', '/': 'slash',
           ',': 'comma', ';': 'semicolon', "'": 'apostrophe', '\\': 'backslash',
           ':': 'shift-semicolon', '_': 'shift-minus', '@': 'shift-2',
           '&': 'shift-7', '|': 'shift-backslash', '~': 'shift-grave_accent'}

class Monitor:
    def __init__(self):
        self.s = socket.create_connection(MON, timeout=10)
        self.s.settimeout(0.1)
        self._drain()
    def _drain(self):
        try:
            while self.s.recv(4096): pass
        except socket.timeout:
            pass
    def cmd(self, c):
        self.s.sendall((c + "\n").encode()); time.sleep(0.06); self._drain()
    def type(self, text, enter=True):
        for ch in text:
            if ch.isupper(): key = "shift-" + ch.lower()
            else: key = SPECIAL.get(ch, ch)
            self.cmd("sendkey " + key)
        if enter: self.cmd("sendkey ret")

# ---------------- console série (expect) ----------------
ANSI = re.compile(rb'\x1b\[[0-9;?]*[a-zA-Z]|\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)?|\x1b\(B|\r')

class Serial:
    def __init__(self):
        self.s = socket.create_connection(SER, timeout=10)
        self.buf = b""
    def send(self, data):
        log(">>> envoi: %r" % data)
        self.s.sendall(data.encode())
    def expect(self, patterns, timeout):
        """patterns: liste de regex bytes; retourne l'index du match le plus
        tôt dans le flux, et consomme le buffer jusqu'à la fin du match."""
        end = min(time.time() + timeout, DEADLINE)
        pats = [re.compile(p) for p in patterns]
        while time.time() < end:
            best = None
            for i, p in enumerate(pats):
                m = p.search(self.buf)
                if m and (best is None or m.start() < best[1].start()):
                    best = (i, m)
            if best:
                self.buf = self.buf[best[1].end():]
                return best[0]
            self.s.settimeout(5)
            try:
                data = self.s.recv(4096)
                if not data: die("connexion série fermée")
                serf.write(data)
                # strip sur l'ensemble : gère les séquences coupées entre 2 recv
                self.buf = ANSI.sub(b"", self.buf + data)[-100000:]
            except socket.timeout:
                pass
        return -1

def main():
    status("RUNNING: connexion")
    mon, ser = Monitor(), Serial()

    # --- 1. passer le menu GRUB de l'ISO puis attendre le boot ---
    log("attente GRUB (12s) puis Enter pour booter l'ISO")
    time.sleep(12); mon.cmd("sendkey ret")
    log("attente du boot de l'ISO (60s)")
    time.sleep(60)

    # --- 2. démarrer un getty série depuis tty1 (via sendkey) ---
    status("RUNNING: activation console série")
    for attempt in range(8):
        log("tty1: systemctl start serial-getty (essai %d)" % (attempt + 1))
        mon.type("systemctl start serial-getty@ttyS0.service")
        time.sleep(3); ser.send("\n")
        if ser.expect([rb"archiso login:", rb"root@archiso"], 30) >= 0:
            break
    else:
        die("pas de console série apres 8 essais")

    if ser.expect([rb"root@archiso"], 3) < 0:      # login si pas deja loggé
        ser.send("root\n")
        i = ser.expect([rb"root@archiso", rb"Password:"], 20)
        if i == 1:
            ser.send("\n")                          # mot de passe vide sur l'ISO
            i = ser.expect([rb"root@archiso"], 20)
        if i < 0: die("login root impossible")
    log("console série OK, shell root sur l'ISO")

    # --- 3. lancer le script phase 1 (le fameux curl | bash) ---
    status("RUNNING: phase 1 (partitionnement + pacstrap)")
    ser.send(CURL_CMD + "\n")
    if ser.expect([rb"Taper OUI pour continuer"], 60) < 0: die("prompt OUI jamais vu (curl KO ?)")
    ser.send("OUI\n")

    # --- 4. phases 1+2 : répondre aux 4 prompts passwd, attendre la fin ---
    status("RUNNING: install en cours (long : pacstrap + paquets)")
    while True:
        i = ser.expect([rb"[Nn]ew password:?", rb"Entr\xc3\xa9e pour rebooter",
                        rb"ERREUR", rb"error: failed", rb"FAILED",
                        rb"curl: \(\d+\)", rb"command not found",
                        rb"Failed to enable"], 70 * 60)
        if i == 0:
            ser.send(PASSWORD + "\n")
            log("mot de passe envoyé")
        elif i == 1:
            log("phases 1+2 terminées !"); break
        elif i == -1:
            die("timeout pendant l'install")
        else:
            time.sleep(3)
            die("erreur détectée pendant l'install (voir serial.log)")

    # --- 5. harnais : activer getty série sur le système installé ---
    # (Ctrl-C sur le read, remount, enable, puis reboot manuel)
    status("RUNNING: activation getty série système installé + reboot")
    ser.send("\x03"); time.sleep(2)
    ser.send("mount /dev/nvme0n1p2 /mnt && arch-chroot /mnt "
             "systemctl enable serial-getty@ttyS0.service && "
             "umount -R /mnt && echo HARNESS_OK && reboot\n")
    if ser.expect([rb"HARNESS_OK"], 60) < 0: die("échec activation getty série")

    # --- 6. boot du système installé, login mabe ---
    status("RUNNING: attente boot du système installé")
    if ser.expect([rb"desktop login:"], 300) < 0: die("pas de login apres reboot (GRUB KO ?)")
    log("le système installé BOOTE — login mabe")
    ser.send("mabe\n")
    if ser.expect([rb"Password:"], 20) < 0: die("pas de prompt password")
    ser.send(PASSWORD + "\n")
    if ser.expect([rb"\$"], 20) < 0: die("login mabe échoué")

    # --- 7. vérifications ---
    status("RUNNING: vérifications post-install")
    ser.send("{ echo ==SERVICES==; sudo systemctl is-enabled NetworkManager bluetooth cronie "
             "systemd-timesyncd fstrim.timer getty@tty2 nvidia-suspend; "
             "echo ==SWAP==; swapon --show; zramctl; "
             "echo ==LOCALE==; cat /etc/locale.conf /etc/vconsole.conf /etc/hostname; "
             "echo ==GRUB==; ls /boot/grub/grub.cfg; "
             "echo ==PKGS==; pacman -Qqen | wc -l; "
             "echo ==FAILED==; systemctl --failed --no-legend; "
             "echo ==V''DONE==; } 2>&1 | tee /dev/ttyS0 >/dev/null\n")
    # marqueur coupé par '' : l'écho de la commande ne peut pas matcher
    if ser.expect([rb"==VDONE=="], 60) < 0: die("vérifications sans réponse")
    log("vérifications OK (détail dans serial.log)")

    ser.send("sudo poweroff\n")
    time.sleep(10)
    status("SUCCESS: install complète, boot OK, vérifs dans serial.log")

if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as e:
        die("exception: %r" % e)
