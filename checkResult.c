#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
double inner_product_1d_double(int size, double *arr1, double *arr2) { double result = 0.0;for (int i = 0; i < size; i++) {result += arr1[i] * arr2[i];}return result;}
int inner_product_1d_int(int size, int *arr1, int *arr2) {int result = 0.0;for (int i = 0; i < size; i++) {result += arr1[i] * arr2[i];}return result;}
int* add_arrays_1d_int(int size, int* arr1, int* arr2) {int* result = (int*)malloc(size * sizeof(int));if (result == NULL) {printf("Memory allocation failed\n");exit(1);}for (int i = 0; i < size; i++) {result[i] = arr1[i] + arr2[i];}return result;}
double* add_arrays_1d_double(int size, double* arr1, double* arr2) {double* result = (double*)malloc(size * sizeof(double));if (result == NULL) {printf("Memory allocation failed\n");exit(1);}for (int i = 0; i < size; i++) {result[i] = arr1[i] + arr2[i];}return result;}        
void print_1d_int(int size, int* result, bool isNewline){printf("{ ");for (int i=0;i<size;i++){if (i == size-1) printf("%d }", result[i]);else printf("%d, ", result[i]);}if (isNewline) printf("\n");}
void print_1d_double(int size, double* result, bool isNewline){printf("{ ");for (int i=0;i<size;i++){if (i == size-1) printf("%g }", result[i]);else printf("%g, ", result[i]);}if (isNewline) printf("\n");}
int main() {
    double i = 1.5;
    double j = 3.14;
    double k = 2.8;
    printf("%g", i + j * k);
    printf("\n");
    printf("%g", i * ( j + k ));
    printf("\n");
}
