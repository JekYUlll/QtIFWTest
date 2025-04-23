//
// Created by horeb on 25-4-21.
//

#include <iostream>
#include "helper.h"

int main(int argc, char* argv[]) {
    std::cout << "Running app1 (component 1)" << std::endl;
    std::cout << "Received arguments:" << std::endl;
    for (int i = 0; i < argc; ++i) {
        std::cout << "  argv[" << i << "] = " << argv[i] << std::endl;
    }

    say_hello();  // 来自 libhelper.so

    std::cin.get();
    return 0;
}

