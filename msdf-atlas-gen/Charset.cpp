
#include "Charset.h"

namespace msdf_atlas {

static Charset createAsciiCharset() {
    Charset ascii;
    for (unicode_t cp = 0x20; cp < 0x7f; ++cp)
        ascii.add(cp);
    return ascii;
}

Charset Charset::ascii() {
    static Charset ascii = createAsciiCharset();
    return ascii;
}

void Charset::add(unicode_t cp) {
    codepoints.insert(cp);
}

void Charset::remove(unicode_t cp) {
    codepoints.erase(cp);
}

size_t Charset::size() const {
    return codepoints.size();
}

bool Charset::empty() const {
    return codepoints.empty();
}

std::set<unicode_t, std::less<unicode_t>, Allocator<unicode_t>>::const_iterator Charset::begin() const {
    return codepoints.begin();
}

std::set<unicode_t, std::less<unicode_t>,  Allocator<unicode_t>>::const_iterator Charset::end() const {
    return codepoints.end();
}

}
