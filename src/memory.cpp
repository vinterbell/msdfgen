#include <memory>

extern "C" void *msdfAllocate(size_t size)
{
    return std::malloc(size);
}

extern "C" void msdfDeallocate(void *ptr, size_t size)
{
    std::free(ptr);
}