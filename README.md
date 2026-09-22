# WiFi Scanner & Security Auditor (অচেনা গেমার)

একটি মেনু-চালিত Bash স্ক্রিপ্ট, যা দিয়ে WiFi নেটওয়ার্ক স্ক্যান এবং নিরাপত্তা যাচাই (vulnerability assessment) করা যায়।

> ⚠️ **সতর্কীকরণ:** এই টুলটি শুধুমাত্র নিজের মালিকানাধীন বা লিখিত অনুমতিপ্রাপ্ত নেটওয়ার্কে ব্যবহার করুন। অনুমতি ছাড়া অন্য কারো নেটওয়ার্কে ব্যবহার করা বেআইনি এবং ফৌজদারি অপরাধ।

---

## প্রয়োজনীয়তা (Requirements)

- **OS:** Linux (Debian/Ubuntu/Kali বেসড ডিস্ট্রো সবচেয়ে ভালো কাজ করে)
- **Root/sudo অ্যাক্সেস** (মনিটর মোড ও প্যাকেট ক্যাপচারের জন্য আবশ্যক)
- **WiFi অ্যাডাপ্টার** যা মনিটর মোড সাপোর্ট করে

### প্রয়োজনীয় প্যাকেজ

| প্যাকেজ | কাজ |
|---|---|
| `aircrack-ng` | হ্যান্ডশেক ক্যাপচার ও পাসওয়ার্ড ক্র্যাকিং |
| `reaver` | WPS ভালনারেবিলিটি টেস্ট |
| `wireless-tools` | `iwconfig`, `iwlist` কমান্ড |
| `network-manager` | `nmcli` কমান্ড |

---

## ইনস্টলেশন

### ধাপ ১: প্যাকেজ ইনস্টল করুন

**Debian / Ubuntu / Kali:**
```bash
sudo apt update
sudo apt install -y aircrack-ng reaver wireless-tools network-manager
```

**Arch Linux:**
```bash
sudo pacman -Syu aircrack-ng reaver wireless_tools networkmanager
```

**Termux:**
```bash
git clone https://github.com/bangladeshcyberspectre/WIFI-SCANNER.git
cd 
```

### ধাপ ২: স্ক্রিপ্ট ফাইল প্রস্তুত করুন

স্ক্রিপ্টটি একটি ফাইলে সেভ করুন, যেমন `wifiscan.sh`, তারপর এক্সিকিউট পারমিশন দিন:

```bash
chmod +x wifiscan.sh
```

### ধাপ ৩: রান করুন (root হিসেবে)

```bash
sudo ./wifiscan.sh
```

> স্ক্রিপ্টটি রুট ছাড়া চলবে না — শুরুতেই এটি `EUID` চেক করে বন্ধ হয়ে যাবে।

---

## ওয়ার্ডলিস্ট (পাসওয়ার্ড ক্র্যাকিংয়ের জন্য, ঐচ্ছিক)

Kali Linux-এ সাধারণত `rockyou.txt` প্রি-ইনস্টল থাকে (gzip করা):

```bash
sudo gunzip -k /usr/share/wordlists/rockyou.txt.gz
```

অন্য ডিস্ট্রোতে না থাকলে:
```bash
sudo apt install wordlists
```

---

## ব্যবহারের ধাপ সংক্ষেপে

1. স্ক্রিপ্ট চালু করলে মেইন মেনু আসবে (Scan, WPS Test, Handshake Capture, Crack, About)।
2. **WiFi Network Scan** — আশেপাশের নেটওয়ার্ক লিস্ট দেখাবে ও ভালনারেবিলিটি চেক করবে।
3. **Vulnerability Test / Handshake Capture** চালানোর আগে স্ক্রিপ্ট অনুমতি সংক্রান্ত প্রশ্ন করবে — সততার সাথে উত্তর দিন এবং নিজের নেটওয়ার্ক ছাড়া ব্যবহার করবেন না।
4. মনিটর মোড চালু/বন্ধ স্বয়ংক্রিয়ভাবে হ্যান্ডেল হয় (`airmon-ng`)।

---

## সমস্যা সমাধান (Troubleshooting)

- **"No wireless interface found"** → `iwconfig` দিয়ে চেক করুন আপনার অ্যাডাপ্টার মনিটর মোড সাপোর্ট করে কি না।
- **"Missing tools" সতর্কতা** → উপরের ইনস্টলেশন কমান্ডগুলো আবার রান করুন।
- **Wi-Fi সংযোগ বন্ধ হয়ে যাচ্ছে** → স্ক্রিপ্ট চালানোর সময় `airmon-ng check kill` NetworkManager বন্ধ করে দেয়; স্ক্রিপ্ট থেকে বের হলে (`0` চাপুন) এটি স্বয়ংক্রিয়ভাবে আবার চালু হবে।

---

## লাইসেন্স ও দায়বদ্ধতা

এই টুলটি শুধুমাত্র **শিক্ষামূলক ও অনুমোদিত** নিরাপত্তা পরীক্ষার জন্য। ব্যবহারকারী নিজ দায়িত্বে ব্যবহার করবেন; নির্মাতা কোনো অপব্যবহারের দায় নেবে না।
