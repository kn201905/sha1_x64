
static inline __m256i enc_reshuffle(const __m256i input) {

	// translation from SSE into AVX2 of procedure
	// https://github.com/WojciechMula/base64simd/blob/master/encode/unpack_bigendian.cpp

	// _mm256_shuffle_epi8 = vpshufb
	const __m256i in = _mm256_shuffle_epi8(input, _mm256_set_epi8(
		10, 11,  9, 10,
		7,  8,  6,  7,
		4,  5,  3,  4,
		1,  2,  0,  1,

		14, 15, 13, 14,
		11, 12, 10, 11,
		8,  9,  7,  8,
		5,  6,  4,  5
	));

	// _mm256_and_si256 = vpand
	const __m256i t0 = _mm256_and_si256(in, _mm256_set1_epi32(0x0fc0fc00));
	// _mm256_mulhi_epu16 = vpmulhuw (= high unsigned word)
	const __m256i t1 = _mm256_mulhi_epu16(t0, _mm256_set1_epi32(0x04000040));

	// _mm256_and_si256 = vpand
	const __m256i t2 = _mm256_and_si256(in, _mm256_set1_epi32(0x003f03f0));
	// _mm256_mullo_epi16 = vpmullw (= low word)
	const __m256i t3 = _mm256_mullo_epi16(t2, _mm256_set1_epi32(0x01000010));

	// _mm256_or_si256 = vpor
	return _mm256_or_si256(t1, t3);
}


static inline __m256i enc_translate(const __m256i in) {
	const __m256i lut = _mm256_setr_epi8(
		65, 71, -4, -4, -4, -4, -4, -4, -4, -4,		// 0 - 9
		-4, -4, -19, -16, 0, 0,  // 10 - 15
		65, 71, -4, -4, -4, -4, -4, -4, -4, -4,
		-4, -4, -19, -16, 0, 0
	);

	// _mm256_subs_epu8 = vpsubusb（= unsigned saturation byte）
	// indices は 0 - 12 の値となる
	__m256i indices = _mm256_subs_epu8(in, _mm256_set1_epi8(51));
	// _mm256_cmpgt_epi8 = vpcmpgtb（greater than byte）
	// mask は 0 - 25 のところが 0 となる
	__m256i mask = _mm256_cmpgt_epi8((in), _mm256_set1_epi8(25));
	// _mm256_sub_epi8 = vpsubb
	// in: 0 - 25 -> 0 - 0 = 0
	//     26 - 51 -> 0 - 0xff = 1
	//     52 -> 1 - 0xff = 2
	//     53 -> 2 - 0xff = 3
	//     ...
	//     63 -> 12 - 0xff = 13
	indices = _mm256_sub_epi8(indices, mask);
	// _mm256_add_epi8 = vpaddb
	// _mm256_shuffle_epi8 = vpshufb
	// _mm256_shuffle_epi8(lut, indices)
	// in: 0 - 25 -> indices: 0 -> 65
	//     26 - 51 -> 1 -> 71
	//     52 -> 2 -> -4
	//     53 -> 3 -> -4
	// ...
	//     61 -> 11 -> -4 => 61 - 4 = 57 = 0x39 = '9'
	//     62 -> 12 -> -19 => 62 - 19 = 43 = 0x2b = '+'
	//     63 -> 13 -> -16 => 63 - 16 = 47 = 0x2f = '/'
	__m256i out = _mm256_add_epi8(in, _mm256_shuffle_epi8(lut, indices));
	return out;
}


size_t fast_avx2_base64_encode(char* dest, const char* str, size_t len) {
	const char* const dest_orig = dest;

	if(len >= 32 - 4) {
		// first load is masked
		__m256i inputvector = _mm256_maskload_epi32((int const*)(str - 4), _mm256_set_epi32(
			0x80000000,
			0x80000000,
			0x80000000,
			0x80000000,

			0x80000000,
			0x80000000,
			0x80000000,
			0x00000000 // we do not load the first 4 bytes
		));
		//////////
		// Intel docs: Faults occur only due to mask-bit required memory accesses that caused the faults.
		// Faults will not occur due to referencing any memory location if the corresponding mask bit for
		//that memory location is 0. For example, no faults will be detected if the mask bits are all zero.
		////////////
		while (true) {
			inputvector = enc_reshuffle(inputvector);
			inputvector = enc_translate(inputvector);
			_mm256_storeu_si256((__m256i *)dest, inputvector);
			str += 24;
			dest += 32;
			len -= 24;

			if(len >= 32) {
				inputvector = _mm256_loadu_si256((__m256i *)(str - 4)); // no need for a mask here
				// we could do a mask load as long as len >= 24
			} else {
				break;
			}
		}
	}
	size_t scalarret = chromium_base64_encode(dest, str, len);
	if (scalarret == MODP_B64_ERROR) return MODP_B64_ERROR;

	return (dest - dest_orig) + scalarret;
}
