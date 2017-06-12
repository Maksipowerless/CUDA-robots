#include <iostream>
#include <time.h>
#include <cmath>
#include <vector>
#include<stdlib.h>
#include"/opt/software/nvidia/cuda-8.0/include/cuda.h"

using namespace std;
#define N 1000
#define threads 10

int map[N][N];
int heightOfRobot = 50;
int heightOfStantion = 120;
int xStatic = 66;
int yStatic = 55;


--global__ void findLine(int** a)
{
 int tid = blockIdx.x;
	
    for(int i=0; i<N; i++)
	{
	 if(tid < threads)
	 {
	   bresenhamLine(xStatic, yStatic, tid,0);
	   bresenhamLine(xStatic, yStatic, tid, N-1);
           bresenhamLine(xStatic, yStatic, 0, tid);
           bresenhamLine(xStatic, yStatic, N-1, tid);
	 }
       }
}

void findDarkArea(vector<pair<int, int> >& coord, vector<pair<int, int> >& versities)
{
    float alpha = 0;
    pair<int,int> tempPair;
    pair<int,int> currentPoint;

    while(versities.size() != 0)
    {
        //поиск точки с меньшим полярным углом от стационарной
        for(int i=0; i<versities.size(); i++)
        {
            float A = versities[i].first;
            float B = sqrt(pow(versities[i].first, 2) + pow((heightOfStantion - versities[i].second), 2));
            float temp = 0;
            temp = A/B;
            if(temp > alpha)
            {
                alpha = temp;
                tempPair = coord[i];
                currentPoint = versities[i];
            }
        }

        //проверка на видимость всех точек за текущей
	int number  = 0;
	for(int j=0; j<versities.size(); j++)
	{
	  if(versities[j] == currentPoint)
		{
		  number = j;
		  break;
		}
	}	

        for(int i = number + 1; i< versities.size(); i++)
        {
            if(versities[i].second + heightOfRobot < currentPoint.second)
            {
                map[coord[i].first][coord[i].second] = 999;
                coord.erase(coord.begin() + i);
                versities.erase(versities.begin() + i);
            }
        }

	for(int j=0; j<coord.size(); j++)
	{
		if(coord[j] == tempPair)
		{
		  coord.erase(coord.begin() + j);
		  versities.erase(versities.begin() +j);
		  break;
		}
	}
    
        alpha = 0;
    }
}


void bresenhamLine(int x1, int y1, int x2, int y2)
{
    const int deltaX = abs(x2 - x1);
    const int deltaY = abs(y2 - y1);
    const int signX = x1 < x2 ? 1 : -1;
    const int signY = y1 < y2 ? 1 : -1;
    int error = deltaX - deltaY;
    int count = 0;//cчеткик кол-ва точек

    vector<pair<int,int> > versities;
    vector<pair<int,int> > coord;

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

        pair<int,int> pair;
        pair.first = count;
        pair.second = map[x1][y1];
        versities.push_back(pair);

        pair.first = x1;
        pair.second = y1;
        coord.push_back(pair);
    }
	findDarkArea(coord, versities);
}

int main()
{
    srand(time(0));
       for(int i=0; i<N; i++)
        for(int j=0; j<N; j++)
            map[i][j] = rand() % 80 +5;
   
    map[xStatic][yStatic] = heightOfStantion;

	int** dev_a;
	cudaMalloc((void***) &dev_a, threads*sizeof(int));
	for(int i=0; i<threads; i++)
	{
		cudaMalloc((void**) &dev_a[i], threads*sizeof(int)); 
	}
	
	for(int i=0; i< N; i++)
	{
		for(int j=0; j< N; j++)
		{
			cout<<map[i][j] <<" ";
		}
		cout<<"\n";
	}
    return 0;
}
