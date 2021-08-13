
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
