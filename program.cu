#include <iostream>
#include <time.h>
#include <cmath>
#include <vector>
#include <stdlib.h>
#include"/opt/software/nvidia/cuda-8.0/include/cuda.h"
#include <stdio.h>

using namespace std;
#define N 1000
#define threads 74  
#define blocks 54
#define X 500
#define Y 500git 

__device__ int MAP[N][N];//карта на GPU
__device__ int SUM = 4*N-4;//количество крайних точек

__device__ void bresenhamLine(int x1, int y1, int x2, int y2)
{
    const int heightOfRobot = 50;
    const int heightOfStantion = 120;
    const int deltaX = abs(x2 - x1);
    const int deltaY = abs(y2 - y1);
    const int signX = x1 < x2 ? 1 : -1;
    const int signY = y1 < y2 ? 1 : -1;
    int error = deltaX - deltaY;
    int count = 0;//cчеткик кол-ва точек

    int numOfVersities[1000];//массив с номерами точек
    int heightOfVersities[1000];//массив с высотами точек
    int xCoord[1000];//массив с x координатами
    int yCoord[1000];//массив с y координатами
    
      while(x1 != x2 || y1 != y2)
    {
        count++;
        const int error2 = error * 2;
        if(error2 > -deltaY)
        {
            error -= deltaY;
            x1 += signX;
        }
        if(error2 < deltaX)

        {
            error += deltaX;
            y1 += signY;
        }

        numOfVersities[count-1]=count;
        heightOfVersities[count-1]=MAP[x1][y1];
        xCoord[count-1]=x1;
        yCoord[count-1]=y1;
    }

    float alpha = 0;
    int tempNumber = 0;
    int tempHeight = 0;
    int tempX = 0;
    int tempY = 0;
    int sizeOfLine = count;//кол-во точек в прямой
    count = 0;//количество удаленных точек
    int delElement = -99;//признак удаленного элемента в массиве

    while(count != sizeOfLine)
    {
        int number  = 0;//номер вершины в массиве, через которую удаляют невидимые вершины
        //поиск точки с меньшим полярным углом от стационарной
        for(int i=0; i < sizeOfLine; i++)
        {
            if(numOfVersities[i] != delElement)
            {
                float A = numOfVersities[i];
                float B = sqrtf(numOfVersities[i]*numOfVersities[i] + 
                          (heightOfStantion - heightOfVersities[i])*(heightOfStantion - heightOfVersities[i]));
                float temp = A/B;
                if(temp > alpha)
                {
                    alpha = temp;
                    tempNumber = numOfVersities[i];
                    tempHeight = heightOfVersities[i];
                    tempX = xCoord[i];
                    tempY = yCoord[i];
                    number = i;
                }
            }
        }

        //удаление невидимых точек за текущей
        for(int i = number + 1; i < sizeOfLine; i++)
        {
            if(heightOfVersities[i] != delElement && heightOfVersities[i] + heightOfRobot < tempHeight)
            {
                MAP[xCoord[i]][yCoord[i]] = -999;
                numOfVersities[i]= delElement;
                heightOfVersities[i]= delElement;
                count++;
            }
        }

        //удаление текущей точки
        numOfVersities[number]= delElement;
        heightOfVersities[number]= delElement;
        count++;

        alpha = 0;
    }
}

__global__ void findLine()
{

 int xStatic = X;
 int yStatic = Y;
 int tid = threadIdx.x;
 int bid = blockIdx.x;
for(int i = (bid*threads+tid)*SUM/(threads*blocks); i < (bid*threads+tid+1)*SUM/(threads*blocks); i++)
{ 
	int column = 0;
	int str = 0;

	if(i <= SUM/4)
	{
	  column = i;
	}
	else if(i <=  SUM/2)
	{
	  column = N-1;
	  str = i-(N-1);
	}
	else if(i <= 3*SUM/4)
	{
	  str = N-1;
	  column = N-1-i+2*(N-1);
	}
	else
	{
	   str = i-3*(N-1);
	}
	

      bresenhamLine(xStatic, yStatic, str, column);
     //MAP[str][column]=0;
}
 //  __syncthreads();
}


int map[N][N];
 
int main()
{
    srand(time(0));
       for(int i=0; i<N; i++)
        for(int j=0; j<N; j++)
            map[i][j] = rand() % 80 +5;
   
/*
for(int i=0; i< N; i++)
	{
		for(int j=0; j< N; j++)
		{
			printf("%d",map[i][j]);
			printf(" ");
		}
		printf("\n");
	}
  printf("\n");
*/
  cudaSetDevice(0);

 cudaEvent_t timStart, timCopyTo, timStopWork, timCopyFrom;
 cudaEventCreate(&timStart);
 cudaEventCreate(&timCopyTo);
 cudaEventCreate(&timStopWork);
 cudaEventCreate(&timCopyFrom);

 cudaEventRecord(timStart);
 	
  void* a_DATA;
  cudaGetSymbolAddress(&a_DATA, MAP);
  cudaMemcpy(a_DATA, map, sizeof(map), cudaMemcpyHostToDevice);

  cudaEventRecord(timCopyTo);

  dim3 numThreads = dim3(threads);
  dim3 numBlocks = dim3(blocks);

  findLine<<<numBlocks, numThreads>>>();

  cudaEventRecord(timStopWork);

  cudaMemcpy(map, a_DATA, sizeof(map), cudaMemcpyDeviceToHost);   

  cudaEventRecord(timCopyFrom);
/*
for(int i=0; i< N; i++)
	{
		for(int j=0; j< N; j++)
		{
			printf("%d",map[i][j]);
			printf(" ");
		}
		printf("\n");
	}
*/
float t1,t2,t3;
cudaEventElapsedTime(&t1,timStart, timCopyTo);
cudaEventElapsedTime(&t2, timCopyTo,timStopWork);
cudaEventElapsedTime(&t3,timStopWork, timCopyFrom);

cout<< "\n"<<t1 << " "<<t2<<" "<< t3 << "\n";
    return 0;
}
