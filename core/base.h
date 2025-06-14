
#pragma once

// This file needs to be included first for all MSDFgen sources

#ifndef MSDFGEN_PUBLIC
// #include <msdfgen/msdfgen-config.h>
#endif

#include <cstddef>
#include <memory>

namespace msdfgen
{

    typedef unsigned char byte;

    // needs override
    extern "C" void *msdfAllocate(size_t size);
    extern "C" void msdfDeallocate(void *ptr, size_t size);

    template <typename T, typename... Args>
    inline T* make(Args&&... args)
    {
        T* ptr = (T*)msdfAllocate(sizeof(T));
        if (!ptr) {
            throw std::bad_alloc();
        }
        new(ptr) T(std::forward<Args>(args)...);
        return ptr;
    }

    template <typename T>
    inline void destroy(T* ptr, size_t size = sizeof(T))
    {
        if (ptr) {
            ptr->~T();
            msdfDeallocate(ptr, size);
        }
    }

    template <typename T>
    class Allocator : public std::allocator<T>
    {
    public:
        typedef size_t size_type;
        typedef T *pointer;
        typedef const T *const_pointer;

        template <typename U>
        struct rebind
        {
            typedef Allocator<U> other;
        };

        pointer allocate(size_type n, const void *hint = 0)
        {
            pointer returned = (pointer)msdfAllocate(n * sizeof(T));
            if (!returned) {
                throw std::bad_alloc();
            }
            return returned;
        }

        void deallocate(pointer p, size_type n)
        {
            msdfDeallocate(p, n * sizeof(T));
        }

        Allocator() throw() : std::allocator<T>() {}
        Allocator(const Allocator &a) throw() : std::allocator<T>(a) {}
        template <class U>
        Allocator(const Allocator<U> &a) throw() : std::allocator<T>(a) {}
        ~Allocator() throw() {}
    };
}
