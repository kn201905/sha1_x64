#!/bin/bash

unset tmpfile
tmpfile=$(mktemp)

function rm_tmpfile {
  rm -f "$tmpfile"
  echo 'rm -f tmpfile ... OK'
}
trap rm_tmpfile EXIT

function assert() {
	str_to_hash=$1
	hash_val=$2
	result=$(echo $str_to_hash | ./main 3> $tmpfile)
		
	if [ "$hash_val" = "$result" ]; then
		echo "ooo ハッシュ値 OK -> ${result}"
	else
		echo "xxx ハッシュ値 NG -> ${result}"
		return
	fi

	str_base64="$(cat $tmpfile)="

	if [ "$str_base64" = "$3" ]; then
		echo -e "ooo base64 文字列 OK -> ${str_base64}\n"
	else
		echo -e "xxx base64 文字列 NG -> ${str_base64}\n"
	fi
}

assert 'dGhlIHNhbXBsZSBub25jZQ'\
	'b37a4f2c c0624f16 90f64606 cf385945 b2bec4ea'\
	's3pPLMBiTxaQ9kYGzzhZRbK+xOo='

assert 'E4WSEcseoWr4csPLS2QJHA'\
	'ede40286 00ad40c9 d520b79f 2403ba74 ae49c0f7'\
	'7eQChgCtQMnVILefJAO6dK5JwPc='
	
assert 'zYuFKiL/3y3UA63cCi8V6g'\
	'7f8bceb1 ca9fabb2 faab7af2 79894a73 dbf698e5'\
	'f4vOscqfq7L6q3ryeYlKc9v2mOU='

