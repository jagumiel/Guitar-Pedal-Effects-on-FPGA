#define au_in (volatile short *) 0x0081050  //Input memory address
#define au_out (volatile short *) 0x0081040
#define ch0 (volatile short *) 0x0081020  //Channel 0 pot mem addr
#define samp_rdy (volatile int *) 0x0081030 //Indicates if a new sample is ready
#define BUFF_SIZE (48000)
#define REV_SIZE (4800)


/* void main(){ //Distortion

	while (1){
		short dist_pos=*ch0;
		short dist_neg=-(*ch0);
		
		if((*(samp_rdy + 0x3)==0x1)){
			if(*au_in>0){
				if(*au_in<dist_pos){
					*au_out = *au_in;
				}else{
					*au_out = dist_pos;
				}
			}else{
				if(*au_in>dist_neg){
					*au_out = *au_in;
				}else{
					*au_out = dist_neg;
				}
			}
			*(samp_rdy + 0x3)=0x0;
		}
	}
} */



/* void main(){ //Reverb Cathedral
    static short buff[REV_SIZE];
	int j=REV_SIZE-2000;
    for(int i=0; i<REV_SIZE;){
        if(*(samp_rdy + 0x3)){ //If there's a new sample
            buff[i]= (short)*au_in;
			i++;
            *(samp_rdy + 0x3)= 0;
        }
    }

    while (1){
        for(int i=0; i<REV_SIZE;){
            if(*(samp_rdy + 0x3)){
                *au_out = (buff[i]/4) +(buff[j]/2)+ ((*au_in)/2);	//Reproduces actual sample + delayed sample
                buff[i] = (short)*au_out;		//Replaces the sample in the array for the new one
				i++;
				if(j==REV_SIZE){
					j=0;
				}else{
					j++;
				}
                *(samp_rdy + 0x3)= 0;
            }
        }
    }
} */


/* void main(){ //Reverb
    static short buff[REV_SIZE];
    for(int i=0; i<REV_SIZE;){
        if(*(samp_rdy + 0x3)){ //If there's a new sample
            buff[i]= (short)*au_in;
			i++;
            *(samp_rdy + 0x3)= 0;
        }
    }

    while (1){
        for(int i=0; i<REV_SIZE;){
            if(*(samp_rdy + 0x3)){
                *au_out = (buff[i]/2) + (*au_in);	//Reproduces actual sample + delayed sample
                buff[i] = (short)*au_out;		//Replaces the sample in the array for the new one
				i++;
                *(samp_rdy + 0x3)= 0;
            }
        }
    }
} */


/* void main(){ //ECHO
    static short buff[BUFF_SIZE];
    for(int i=0; i<BUFF_SIZE;){
        if(*(samp_rdy + 0x3)){ //If there's a new sample
            buff[i]= (short)*au_in;
			i++;
            *(samp_rdy + 0x3)= 0;
        }
    }

    while (1){
        for(int i=0; i<BUFF_SIZE;){
            if(*(samp_rdy + 0x3)){
                *au_out = (buff[i]/2) + (*au_in);	//Reproduces actual sample + delayed sample
                buff[i] = (short)*au_out;		//Replaces the sample in the array for the new one
				i++;
                *(samp_rdy + 0x3)= 0;
            }
        }
    }
} */

void main(){ //REPLAY
    static short buff[BUFF_SIZE];
    for(int i=0; i<BUFF_SIZE;){
        if(*(samp_rdy + 0x3)){ //If there's a new sample
            buff[i]= (short)*au_in;
			i++;
            *(samp_rdy + 0x3)= 0;
        }
    }

    while (1){
        for(int i=0; i<BUFF_SIZE;){
            if(*(samp_rdy + 0x3)){
                *au_out = (buff[i]/2) + (*au_in);	//Reproduces actual sample + delayed sample
                buff[i] = (short)*au_in;		//Replaces the sample in the array for the new one
				i++;
                *(samp_rdy + 0x3)= 0;
            }
        }
    }
}

//Cuando documentes acuerdate del flag del C99.

/*void main() //BYPASS
{ while (1)
	if((*(samp_rdy + 0x3)==0x1)){
		*au_out = *au_in;
		*(samp_rdy + 0x3)=0x0;
	}
}*/