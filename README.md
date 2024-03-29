# noid

A webservice and Docker image for minting NOIDs

* [NOID: Nice Opaque IDentifier (minter and name resolver)](https://n2t.net/e/noid.html)
* [NOID CPAN module](https://metacpan.org/pod/distribution/Noid/noid)
* CRKN's Name Assigning Authority Number (NAAN) is 69429  (See: [NAAN Registry](https://n2t.net/e/pub/naan_registry.txt))
* This is used as part of an [Archival Resource Key (ARK)](https://arks.org/about/)

## Installation

You will want to specify a volume for the container directory `/noid/dbs`; this is where the noid databases will be stored.

If you need to change the default config, you can find consulted environment variables at the top of `minter.psgi`.

## API

### `POST /mint/:number/:type`

Mints noids. `:number` is the number of noids you want, and `:type` can be one of `collection`, `collections`, `manifest`, `manifests`, `canvas`, `canvases`. e.g. `POST /mint/5/canvases`. It's a valid English sentence, and you'll get back results that look like:

```
"ids": [
  "69429/c0...",
  "69429/c0...",
  "69429/c0...",
  "69429/c0...",
  "69429/c0..."
]
```

If something messes up a useful error message will hopefully be generated.
