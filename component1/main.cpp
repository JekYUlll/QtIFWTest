//
// Created by horeb on 25-4-21.
//

#include <iostream>
#include "helper.h"

int main() {
    std::cout << "Running app1 (component 1)" << std::endl;
    say_hello();  // 来自 libhelper.so

    std::cin.get();
    return 0;
}

