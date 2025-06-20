
#include "Charset.h"

#include <cstdio>
#include <string>
#include "utf8.h"

namespace msdf_atlas {

static char escapedChar(char c) {
    switch (c) {
        case '0':
            return '\0';
        case 'n': case 'N':
            return '\n';
        case 'r': case 'R':
            return '\r';
        case 's': case 'S':
            return ' ';
        case 't': case 'T':
            return '\t';
        case '\\': case '"': case '\'':
        default:
            return c;
    }
}

static bool parseInt(int &i, const char *str) {
    i = 0;
    if (str[0] == '0' && (str[1] == 'x' || str[1] == 'X')) { // hex
        str += 2;
        for (; *str; ++str) {
            if (*str >= '0' && *str <= '9') {
                i <<= 4;
                i += *str-'0';
            } else if (*str >= 'A' && *str <= 'F') {
                i <<= 4;
                i += *str-'A'+10;
            } else if (*str >= 'a' && *str <= 'f') {
                i <<= 4;
                i += *str-'a'+10;
            } else
                return false;
        }
    } else { // dec
        for (; *str; ++str) {
            if (*str >= '0' && *str <= '9') {
                i *= 10;
                i += *str-'0';
            } else
                return false;
        }
    }
    return true;
}

template <int (READ_CHAR)(void *)>
static int readWord(void *userData, std::string &str) {
    while (true) {
        int c = READ_CHAR(userData);
        if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_')
            str.push_back((char) c);
        else
            return c;
    }
}

template <int (READ_CHAR)(void *)>
static bool readString(void *userData, std::string &str, char terminator) {
    bool escape = false;
    while (true) {
        int c = READ_CHAR(userData);
        if (c < 0)
            return false;
        if (escape) {
            str.push_back(escapedChar((char) c));
            escape = false;
        } else {
            if (c == terminator)
                return true;
            else if (c == '\\')
                escape = true;
            else
                str.push_back((char) c);
        }
    }
}

template <int (READ_CHAR)(void *), void (ADD)(void *, unicode_t), bool (INCLUDE)(void *, const std::string &)>
static bool charsetParse(void *userData, bool disableCharLiterals, bool disableInclude) {

    enum {
        CLEAR,
        TIGHT,
        RANGE_BRACKET,
        RANGE_START,
        RANGE_SEPARATOR,
        RANGE_END
    } state = CLEAR;

    std::string buffer;
    std::vector<unicode_t, Allocator<unicode_t>> unicodeBuffer;
    unicode_t rangeStart = 0;
    for (int c = READ_CHAR(userData), start = true; c >= 0; start = false) {
        switch (c) {
            case '0': case '1': case '2': case '3': case '4': case '5': case '6': case '7': case '8': case '9': // number
                if (!(state == CLEAR || state == RANGE_BRACKET || state == RANGE_SEPARATOR))
                    return false;
                buffer.push_back((char) c);
                c = readWord<READ_CHAR>(userData, buffer);
                {
                    int cp;
                    if (!parseInt(cp, buffer.c_str()))
                        return false;
                    switch (state) {
                        case CLEAR:
                            if (cp >= 0)
                                ADD(userData, (unicode_t) cp);
                            state = TIGHT;
                            break;
                        case RANGE_BRACKET:
                            rangeStart = (unicode_t) cp;
                            state = RANGE_START;
                            break;
                        case RANGE_SEPARATOR:
                            for (unicode_t u = rangeStart; (int) u <= cp; ++u)
                                ADD(userData, u);
                            state = RANGE_END;
                            break;
                        default:;
                    }
                }
                buffer.clear();
                continue; // next character already read
            case '\'': // single UTF-8 character
                if (!(state == CLEAR || state == RANGE_BRACKET || state == RANGE_SEPARATOR) || disableCharLiterals)
                    return false;
                if (!readString<READ_CHAR>(userData, buffer, '\''))
                    return false;
                utf8Decode(unicodeBuffer, buffer.c_str());
                if (unicodeBuffer.size() == 1) {
                    switch (state) {
                        case CLEAR:
                            if (unicodeBuffer[0] > 0)
                                ADD(userData, unicodeBuffer[0]);
                            state = TIGHT;
                            break;
                        case RANGE_BRACKET:
                            rangeStart = unicodeBuffer[0];
                            state = RANGE_START;
                            break;
                        case RANGE_SEPARATOR:
                            for (unicode_t u = rangeStart; u <= unicodeBuffer[0]; ++u)
                                ADD(userData, u);
                            state = RANGE_END;
                            break;
                        default:;
                    }
                } else
                    return false;
                unicodeBuffer.clear();
                buffer.clear();
                break;
            case '"': // string of UTF-8 characters
                if (state != CLEAR || disableCharLiterals)
                    return false;
                if (!readString<READ_CHAR>(userData, buffer, '"'))
                    return false;
                utf8Decode(unicodeBuffer, buffer.c_str());
                for (unicode_t cp : unicodeBuffer)
                    ADD(userData, cp);
                unicodeBuffer.clear();
                buffer.clear();
                state = TIGHT;
                break;
            case '[': // character range start
                if (state != CLEAR)
                    return false;
                state = RANGE_BRACKET;
                break;
            case ']': // character range end
                if (state == RANGE_END)
                    state = TIGHT;
                else
                    return false;
                break;
            case '@': // annotation
                if (state != CLEAR)
                    return false;
                c = readWord<READ_CHAR>(userData, buffer);
                if (buffer == "include") {
                    while (c == ' ' || c == '\t' || c == '\n' || c == '\r')
                        c = READ_CHAR(userData);
                    if (c != '"')
                        return false;
                    buffer.clear();
                    if (!readString<READ_CHAR>(userData, buffer, '"'))
                        return false;
                    INCLUDE(userData, buffer);
                    state = TIGHT;
                } else
                    return false;
                buffer.clear();
                break;
            case ',': case ';': // separator
                if (!(state == CLEAR || state == TIGHT)) {
                    if (state == RANGE_START)
                        state = RANGE_SEPARATOR;
                    else
                        return false;
                } // else treat as whitespace
                // fallthrough
            case ' ': case '\n': case '\r': case '\t': // whitespace
                if (state == TIGHT)
                    state = CLEAR;
                break;
            case 0xef: // UTF-8 byte order mark
                if (start) {
                    if (!(READ_CHAR(userData) == 0xbb && READ_CHAR(userData) == 0xbf))
                        return false;
                    break;
                }
            default: // unexpected character
                return false;
        }
        c = READ_CHAR(userData);
    }

    return state == CLEAR || state == TIGHT;
}

static std::string combinePath(const char *basePath, const char *relPath) {
    if (relPath[0] == '/' || (relPath[0] && relPath[1] == ':')) // absolute path?
        return relPath;
    int lastSlash = -1;
    for (int i = 0; basePath[i]; ++i)
        if (basePath[i] == '/' || basePath[i] == '\\')
            lastSlash = i;
    if (lastSlash < 0)
        return relPath;
    return std::string(basePath, lastSlash+1)+relPath;
}

struct CharsetLoadData {
    Charset *charset;
    const char *filename;
    bool disableCharLiterals;
    FILE *file;

    static int readChar(void *userData) {
        return fgetc(reinterpret_cast<CharsetLoadData *>(userData)->file);
    }

    static void add(void *userData, unicode_t cp) {
        reinterpret_cast<CharsetLoadData *>(userData)->charset->add(cp);
    }

    static bool include(void *userData, const std::string &path) {
        const CharsetLoadData &ud = *reinterpret_cast<CharsetLoadData *>(userData);
        return ud.charset->load(combinePath(ud.filename, path.c_str()).c_str(), ud.disableCharLiterals);
    }
};

bool Charset::load(const char *filename, bool disableCharLiterals) {
    if (FILE *f = fopen(filename, "rb")) {
        CharsetLoadData userData = { this, filename, disableCharLiterals, f };
        bool success = charsetParse<CharsetLoadData::readChar, CharsetLoadData::add, CharsetLoadData::include>(&userData, disableCharLiterals, false);
        fclose(f);
        return success;
    }
    return false;
}

struct CharsetParseData {
    Charset *charset;
    const char *cur, *end;

    static int readChar(void *userData) {
        CharsetParseData &ud = *reinterpret_cast<CharsetParseData *>(userData);
        return ud.cur < ud.end ? (int) (unsigned char) *ud.cur++ : -1;
    }

    static void add(void *userData, unicode_t cp) {
        reinterpret_cast<CharsetParseData *>(userData)->charset->add(cp);
    }

    static bool include(void *, const std::string &) {
        return false;
    }
};

bool Charset::parse(const char *str, size_t strLength, bool disableCharLiterals) {
    CharsetParseData userData = { this, str, str+strLength };
    return charsetParse<CharsetParseData::readChar, CharsetParseData::add, CharsetParseData::include>(&userData, disableCharLiterals, true);
}

}
