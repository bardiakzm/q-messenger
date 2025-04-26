# qMessenger

⚠️ **Disclaimer**: This tool is intended for legitimate privacy and security purposes. Users are responsible for complying with all applicable laws regarding encryption and communication in their jurisdiction.



## Overview

A secure SMS messaging solution designed for communication in internet-restricted environments.
QMessage is a Flutter-based application that enables secure communication through SMS when internet access is limited or unavailable. It employs multiple layers of security to protect your messages from unwanted surveillance.

## Features

- **AES Encryption**: AES-CBC encryption to secure message content
- **Word-based Obfuscation**: Additional security layer that masks message content
- **Offline Operation**: Works entirely without internet connection
- **Lightweight Design**: Minimal resource usage for optimal performance

## Security Layers

QMessage currently implements:
- AES encryption for baseline security
- Persian word-based obfuscation as an additional protection measure

Coming soon:
- Symmetric key encryption options
- Additional obfuscation methods

## Use Cases

- Communication during internet outages
- Secure messaging in regions with internet restrictions
- Backup communication channel when primary methods are unavailable
- Privacy-focused conversations

## Enhanced Security Recommendations

If you require a higher level of security, consider forking this repository and recompiling with your own personalized environment variables and encryption keys:

1. Fork the repository to your own GitHub account
2. Clone your forked repository locally
3. Create a new `.env` file with your own custom encryption keys
4. Recompile the application
5. Share this customized build only with your trusted contacts

This approach ensures that even if the original application's encryption keys are compromised, your communications remain secure as they're encrypted with keys known only to you and your trusted circle.

## Roadmap
- [ ] Add symmetric encryption options
- [ ] Error handling
- [ ] Implement additional obfuscation techniques
- [ ] Improve key management system
- [ ] Dynamic keys
- [ ] Message verification system
- [ ] Support for more languages
- [ ] PQC

---
