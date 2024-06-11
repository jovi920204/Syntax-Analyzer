#include <stdio.h>
#include <stdlib.h>
double inner_product_1d_double(int size, double *arr1, double *arr2) {
    double result = 0.0;
    for (int i = 0; i < size; i++) {
        result += arr1[i] * arr2[i];
    }
    return result;
}
int inner_product_1d_int(int size, int *arr1, int *arr2) {
    int result = 0.0;
    for (int i = 0; i < size; i++) {
        result += arr1[i] * arr2[i];
    }
    return result;
}
int main() {
    double i = 1.5;
    double j = 3.14;
    double k = 2.8;
    printf("%lf", i + j * k);
    printf("\n");
    printf("%lf", i * ( j + k ));
    printf("\n");
}