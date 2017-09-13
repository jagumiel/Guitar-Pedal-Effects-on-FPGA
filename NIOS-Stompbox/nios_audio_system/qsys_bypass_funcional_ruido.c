#define au_in (volatile short *) 0x0081050  //Input memory address
#define au_out (volatile short *) 0x0081040
#define samp_rdy (volatile int *) 0x0081030 //Indicates if a new sample is ready
#define SAMPLE_BUF_SIZE     (48000)


void main()
{
    static short buff[SAMPLE_BUF_SIZE];
    for(int i = 0; i < SAMPLE_BUF_SIZE; i++)
    {
        if(*(samp_rdy + 0x3)) //If there's a new sample
        {
            buff[i]= (short)*au_in;
            *(samp_rdy + 0x3)= 0;
        }
    }

    while (1)
    {
        for(int i = 0; i < SAMPLE_BUF_SIZE; i++)
        {
            if(*(samp_rdy + 0x3)) //If there's a new sample
            {
                *au_out = (buff[i]/2) + ((*au_in)/2);   //Reproduces actual sample + delayed sample
                buff[i] = (short)*au_in;                //replaces the sample in the array for the new one
                *(samp_rdy + 0x3)= 0;
            }
        }
    }
}



/*void main()
{ while (1)
	if((*(samp_rdy + 0x3)==0x1)){
		*au_out = *au_in;
		*(samp_rdy + 0x3)=0x0;
	}
}*/