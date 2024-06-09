#include <stdio.h>
int main() {
    double i = 1.5;
    double j = 3.14;
    double k = 2.8;
    printf("%lf", i + j * k);
    printf("\n");
    printf("%lf", i * ( j + k ));
    printf("\n");
}