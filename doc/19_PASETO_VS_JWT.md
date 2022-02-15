# PASETO VS JWT

## Token-based Authentication

Insert a diagram here:

### JWT (Jason Web Token)

Encoded(base64 encoded, not encrypted)=> Decoded

Decoded

- Header: Algorithm & Token Type
- Payload: Data
  - id
  - username
  - expired_at
  - etc..
- Verify Signature

Because a token is encoded based on base64, you can decode it without a private/secret key.

#### JWT Signing Algorithms

##### Symmetric Digital Signature Algorithm

- The same secret key is used to sign & verify token.
- For local use: internal services, where the secret key can be shared.
- HS256, HS384, HS512
  - HS256 = HMAC + SHA256
  - HMAC: Hash-based Message Authentication Code
  - SHA: Secure Hash Algorithm
  - 256/384/512: number of output bits

##### Asymmetric Digital Signature Algorithm

- The private key is used to sign token.
- The publick key is used to verify token.
- For public use: internal service signs token, but external service needs to verify it.
- RS256, RS384, RS512 || PS256, PS384, PS512 || ES256, ES384, ES512
  - RS256 = RSA PKCSv1.5 + SHA256 (PKCS: Public-Key Cryptography Standards)
  - PS256 = RSA PSS + SHA256 (PSS: Probabilistic Signature Scheme)
  - ES256 = ECDSA + SHA256 (ECDSA: Elliptic Curve Digital Signature Algorithm)

#### What's the problem of JWT?

Weak Algorithms

- Give developers too many alogrithms to choose
- Some algorithms are known to be vulerable
  - RSA PKCSv1.5: padding oracle attach
  - ECDSA: invalid-curve attack

Trivial Forgery

- Set "alg" header to "none"
- Set "alg" header to "HS256" while the server normally verifies token with a RSA public key

#### PASETO (Platform-Agnostic SEcurity TOkens)

Stronger Algorithms

- Developers don't have to choose the algorithms
- Only need to select the versions of PASETO
- Each version has 1 strong cipher suite
- Only 2 most recent PASETO versions are accepted
  - v1 (compatibale with legacy systems)
    - local: <symmetic key>
      - Authenticated Encryption
      - AES256 CRT + HMAC SHA384
    - public: <asymmetric key>
      - Digital Signature
      - RSA PSS + SHA384
  - v2 (recommended)
    - local: <symmetric key>
      - Authenticated Encryption
      - XChaCha20-Poly1305
    - public: <asymmetric key>
      - Digital Signature
      - Ed25519[EdDSA + Curve25519]

Non-Trivial Forgery

- No more "alg" header or "none" algorithm
- Everything is authenticated
- Encrypted payload for local use <symmetric key>

##### PASETO Structure

Insert a screen capture here
