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
    int i[2] = { 1, 2 };
    int j[2] = {};
    printf("%d", inner_product_1d_int(2, i, j));
}