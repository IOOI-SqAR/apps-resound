/* DONE */

#include <math.h>
#include "fft.h"
	
/*
	1-dimensional FFT algorithm From Numerical Recipies in C.
	This algorithm takes an array of complex numbers (the even
	positions are real, the odd positions are imaginary) of size
	nn*2.  nn MUST be an integer power of 2 (that is, 2, 4, 8, 16,
	etc.).  It also takes isign, which indicates whether it's an
	FFT or an inverse FFT.
	
	For an FFT, the algorithm takes complex values from time=0,
	time=delta, ... time=(nn-2)delta, time=(nn-1)delta.  
	
	For data positions 0 through nn/2, the algorithm returns
	complex values f=0 to f=(1/2)delta .  For data positions nn/2
	through nn-1, the algorithm returns values f=-(1/2)delta down
	to f=1/n delta
	
	These frequencies are apparently stored in complex number format;
	you'll need to convert them to polar coordinates to use them much.

	four1 is 1-offset, due to stupidity from Fortan, so we have a cover
	macro (FOUR1) which converts it to 0-offset.

*/

#define FOUR1(data,nn,isign) four1((data)-1,nn,isign)
	/* Note data must be a pointer! */
	
#define SWAP(a,b) tempr=(a);(a)=(b);(b)=tempr

void four1(float data[],int nn,int isign)
{
        int n,mmax,m,j,istep,i;
        double wtemp,wr,wpr,wpi,wi,theta;
        float tempr,tempi;

        n=nn << 1;
        j=1;
        for (i=1;i<n;i+=2) {
                if (j > i) {
                        SWAP(data[j],data[i]);
                        SWAP(data[j+1],data[i+1]);
                }
                m=n >> 1;
                while (m >= 2 && j > m) {
                        j -= m;
                        m >>= 1;
                }
                j += m;
        }
        mmax=2;
        while (n > mmax) {
                istep=2*mmax;
                theta=6.28318530717959/(isign*mmax);
                wtemp=sin(0.5*theta);
                wpr = -2.0*wtemp*wtemp;
                wpi=sin(theta);
                wr=1.0;
                wi=0.0;
                for (m=1;m<mmax;m+=2) {
                        for (i=m;i<=n;i+=istep) {
                                j=i+mmax;
                                tempr=wr*data[j]-wi*data[j+1];
                                tempi=wr*data[j+1]+wi*data[j];
                                data[j]=data[i]-tempr;
                                data[j+1]=data[i+1]-tempi;
                                data[i] += tempr;
                                data[i+1] += tempi;
                        }
                        wr=(wtemp=wr)*wpr-wi*wpi+wr;
                        wi=wi*wpr+wtemp*wpi+wi;
                }
                mmax=istep;
        }
}

#undef SWAP


/* For this syntactic sugar function, see fft.h */

void fft(float data[],int nn, int isign)
	{
	if (isign==1)
		{
		int x;
		float swap;
				
		FOUR1(data,nn,isign);
		
		/* now move data to good spots */
		   
		for(x=0;x<nn;x++)
			{ swap=data[x]; data[x]=data[nn+x]; data[nn+x]=swap; }
		
		/* now convert to polar coordinates */
		
		for(x=0;x<nn*2;x+=2)
			{
			swap=data[x];	/* real */
			data[x]=sqrt(swap*swap+data[x+1]*data[x+1]);
			data[x+1]=atan2(data[x+1],swap);
			}
		}
	else
		{
		int x;
		float swap;
		
		/* First convert to rectangular coordinates */
		
		for(x=0;x<nn*2;x+=2)
			{
			swap=data[x];
			data[x]=swap*cos(data[x+1]);
			data[x+1]=swap*sin(data[x+1]);
			}		
		
		/* Next move data to proper spots */
	
		for(x=0;x<nn;x++)
			{ swap=data[x]; data[x]=data[nn+x]; data[nn+x]=swap; }
	
		FOUR1(data,nn,isign);
		
		/* Lastly, the inverse must be divided by nn. See Page 410. */
		
		for(x=0;x<nn*2;x++) data[x]/=nn;
		}
	}



