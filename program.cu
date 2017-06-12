#include <iostream>
#include <time.h>
#include <cmath>
#include <vector>
#include <stdlib.h>
#include"/opt/software/nvidia/cuda-8.0/include/cuda.h"
#include <stdio.h>

using namespace std;
#define N 100
#define threads 16

__device__ int MAP[N][N];

__global__ void fillMap(int map[N][N])
{
	for(int i=0; i<N; i++)
	{
		for(int j=0; j<N; j++)
		{
		   MAP[i][j] = map[i][j];
		}
	}
}

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

    for(int i=0; i< 1000; i++)
    {
        numOfVersities[i]=-999;
        heightOfVersities[i]=-999;
        xCoord[i]=-999;
        yCoord[i]=-999;
    }

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

    while(numOfVersities[0] != -999)
    {
        int number  = 0;//номер вершины в массивеm, через которую удаляют невидимые вершины
        //поиск точки с меньшим полярным углом от стационарной
        for(int i=0; i<count-1; i++)
        {
            float A = numOfVersities[i];
            float B = sqrtf(numOfVersities[i]*numOfVersities[i] + 
                          (heightOfStantion - heightOfVersities[i])*(heightOfStantion - heightOfVersities[i]));
            float temp = 0;
            temp = A/B;
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

        //удаление невидимых точек за текущей
        for(int i = number + 1; numOfVersities[i] != -999; i++)
        {
            if(heightOfVersities[i] + heightOfRobot < tempHeight)
            {
                MAP[xCoord[i]][yCoord[i]] = 999;

                numOfVersities[i]=-999;
                heightOfVersities[i]=-999;
                xCoord[i]=-999;
                yCoord[i]=-999;

                for(int j=i; j<count-1; j++)
                {
                    int temp =  numOfVersities[j];
                    numOfVersities[j] = numOfVersities[j+1];
                    numOfVersities[j+1] = temp;

                    temp =  heightOfVersities[j];
                    heightOfVersities[j] = heightOfVersities[j+1];
                    heightOfVersities[j+1] = temp;

                    temp =  xCoord[j];
                    xCoord[j] = xCoord[j+1];
                    xCoord[j+1] = temp;

                    temp =  yCoord[j];
                    yCoord[j] = yCoord[j+1];
                    yCoord[j+1] = temp;

                }
                count--;
            }
        }

        //удаление текущей точки
        numOfVersities[number]=-999;
        heightOfVersities[number]=-999;
        xCoord[number]=-999;
        yCoord[number]=-999;

        for(int j=number; j<count-1; j++)
        {
            int temp =  numOfVersities[j];
            numOfVersities[j] = numOfVersities[j+1];
            numOfVersities[j+1] = temp;

            temp =  heightOfVersities[j];
            heightOfVersities[j] = heightOfVersities[j+1];
            heightOfVersities[j+1] = temp;

            temp =  xCoord[j];
            xCoord[j] = xCoord[j+1];
            xCoord[j+1] = temp;

            temp =  yCoord[j];
            yCoord[j] = yCoord[j+1];
            yCoord[j+1] = temp;

        }

        alpha = 0;
    }
}

__global__ void findLine()
{

 int xStatic = 66;
 int yStatic = 55;
 int tid = blockIdx.x;
	
 bresenhamLine(xStatic, yStatic, tid,0);
 bresenhamLine(xStatic, yStatic, tid, N-1);
 bresenhamLine(xStatic, yStatic, 0, tid);
 bresenhamLine(xStatic, yStatic, N-1, tid);
 

	
       
}


int map[N][N];
 
int main()
{
 int heightOfStantion = 120;
 int xStatic = 66;
 int yStatic = 55;

    srand(time(0));
       for(int i=0; i<N; i++)
        for(int j=0; j<N; j++)
            map[i][j] = rand() % 80 +5;
   
  void* a_DATA;
  cudaGetSymbolAddress(&a_DATA, MAP);
  cudaMemcpy(a_DATA, map, sizeof(map), cudaMemcpyHostToDevice);
  findLine <<<N,N>>>();
  cudaMemcpy(map, a_DATA, sizeof(map), cudaMemcpyDeviceToHost);   

	
for(int i=0; i< N; i++)
	{
		for(int j=0; j< N; j++)
		{
			printf("%d",map[i][j]);
			printf(" ");
		}
		printf("\n");
	}

    return 0;
}
