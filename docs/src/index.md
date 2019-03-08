# Bitcoin.jl Documentation

A Bitcoin library for Julia

## Functions

### Address

```@docs
h160_2_address
address
wif
```

### Transaction

```@docs
txfetch
txinparse
txinserialize
txinvalue
txin_scriptpubkey
txoutparse
txoutserialize
txparse
txserialize
txhash
txid
txfee
txsighash256
txsighash
txinputverify
txverify
txsigninput
txpushsignature
iscoinbase
coinbase_height
```

### Script

```@docs
scriptparse
scriptevaluate
p2pkh_script
p2sh_script
is_p2pkh
is_p2sh
script2address
```

### OP

```@docs
op_ripemd160
op_sha1
op_sha256
op_hash160
op_hash256
op_checksig
op_checksigverify
op_checkmultisig
op_checkmultisigverify
op_checklocktimeverify
op_checksequenceverify
```

### Block

```@docs
blockparse
serialize
hash
id
bip9
bip91
bip141
target
difficulty
check_pow
```

## Buy me a cup of coffee

[Donate Bitcoin](bitcoin:34nvxratCQcQgtbwxMJfkmmxwrxtShTn67)

## Index

```@index
```
