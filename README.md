cat << 'READMEEOF' > README.md
# 🛡️ WiFi Scanner & Security Auditor

**Version:** 1.0  
**Author:** অচেনা গেমার  
**License:** MIT  
**Platform:** Linux (Kali / Parrot / Ubuntu / Debian)

---

## 📖 সূচিপত্র (Table of Contents)

1. [প্রজেক্ট পরিচিতি](#১-প্রজেক্ট-পরিচিতি)
2. [ফিচারসমূহ](#২-ফিচারসমূহ)
3. [সিস্টেম রিকোয়ারমেন্ট](#৩-সিস্টেম-রিকোয়ারমেন্ট)
4. [ইনস্টলেশন প্রসেস](#৪-ইনস্টলেশন-প্রসেস)
5. [Git Clone করার নিয়ম](#৫-git-clone-করার-নিয়ম)
6. [SSH Setup করার নিয়ম](#৬-ssh-setup-করার-নিয়ম)
7. [Dependencies ইনস্টল](#৭-dependencies-ইনস্টল)
8. [টুল চালানোর নিয়ম](#৮-টুল-চালানোর-নিয়ম)
9. [মেনু অপশনসমূহের বিস্তারিত](#৯-মেনু-অপশনসমূহের-বিস্তারিত)
10. [Output Files](#১০-output-files)
11. [Troubleshooting](#১১-troubleshooting)
12. [Uninstall করার নিয়ম](#১২-uninstall-করার-নিয়ম)
13. [FAQ](#১৩-faq)
14. [Legal Disclaimer](#১৪-legal-disclaimer)
15. [License](#১৫-license)

---

## ১. প্রজেক্ট পরিচিতি

**WiFi Scanner & Security Auditor** হলো একটি Bash-ভিত্তিক টুল যা ডিজাইন করা হয়েছে শিক্ষামূলক ও অনুমোদিত পেনিট্রেশন টেস্টিংয়ের জন্য। এটি একটি ইন্টারঅ্যাক্টিভ মেনু প্রদান করে যার মাধ্যমে আপনি:

- আশেপাশের WiFi নেটওয়ার্ক স্ক্যান করতে পারবেন
- নির্বাচিত নেটওয়ার্কের বিস্তারিত তথ্য দেখতে পারবেন
- WPS vulnerability টেস্ট করতে পারবেন
- WPA Handshake ক্যাপচার করতে পারবেন
- পাসওয়ার্ড ক্র্যাক করার চেষ্টা করতে পারবেন

> **⚠️ সতর্কতা:** এই টুলটি শুধুমাত্র নিজের মালিকানাধীন বা লিখিত অনুমতি আছে এমন নেটওয়ার্কে ব্যবহার করুন। অননুমোদিত ব্যবহার আইনত দণ্ডনীয় অপরাধ।

---

## ২. ফিচারসমূহ

| # | ফিচার | বিবরণ |
|---|-------|-------|
| 1 | WiFi Network Scan | আশেপাশের সব WiFi নেটওয়ার্কের SSID, BSSID, চ্যানেল, সিগন্যাল দেখায় |
| 2 | Network Details | নির্বাচিত নেটওয়ার্কের বিস্তারিত তথ্য দেখায় |
| 3 | WPS Vulnerability Test | WPS-enabled AP ডিটেক্ট করে Pixie Dust / PIN attack চালায় |
| 4 | WPA Handshake Capture | airodump-ng ও aireplay-ng দিয়ে হ্যান্ডশেক ক্যাপচার করে |
| 5 | WPA Password Cracking | aircrack-ng দিয়ে পাসওয়ার্ড ক্র্যাক করে |
| 6 | Monitor Mode Auto | স্বয়ংক্রিয়ভাবে monitor mode অন/অফ করে |
| 7 | Colorful Menu | কালারফুল ইন্টারঅ্যাক্টিভ টার্মিনাল ইন্টারফেস |

---

## ৩. সিস্টেম রিকোয়ারমেন্ট

- **Operating System:** Kali Linux, Parrot OS, Ubuntu 20.04+, Debian 10+
- **Privileges:** Root access (sudo)
- **Wireless Adapter:** Monitor mode ও packet injection সাপোর্ট করে এমন WiFi অ্যাডাপ্টার (যেমন: Alfa AWUS036NHA, TP-Link TL-WN722N v1)
- **RAM:** সর্বনিম্ন ২GB
- **Storage:** ৫০০MB ফ্রি স্পেস (wordlist সহ)

---

## ৪. ইনস্টলেশন প্রসেস

### ধাপ ১: সিস্টেম আপডেট করুন

```bash
sudo apt update && sudo apt upgrade -y

sudo apt install -y git curl wget aircrack-ng reaver wireless-tools network-manager

```install
git clone https://github.com/yourusername/wifi-scanner.git
cd wifi-scanner
