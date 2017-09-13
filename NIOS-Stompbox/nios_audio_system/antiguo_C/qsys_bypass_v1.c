#define au_in (volatile short *) 0x0081050
#define au_out (volatile short *) 0x0081040
#define samp_rdy (volatile int *) 0x0081030

/* REPLAY */
void main(){
	short *buff[48000]; //4seg; 384000B; La memoria es de 400KB.
	int i=0;
	while(i<48000){
		if((*(samp_rdy + 0x3)==0x1)){
			*buff[i]= *au_in;
			i++;
			*(samp_rdy + 0x3)=0x0;
		}
	}

	while (1){
		i=0;
		while(i<48000){
			if((*(samp_rdy + 0x3)==0x1)){
				*au_out = buff[i]+(*au_in);
				*buff[i]=*au_in;
				i++;
				*(samp_rdy + 0x3)=0x0;
			}
		}
		
		/*while(i<48000){
			if((*(samp_rdy + 0x3)==0x1)){
			//	*au_out = buff[i]+(*au_in);
				*au_out = *au_in;
				//*au_out = *au_in + buff[i];
				i++;
				*(samp_rdy + 0x3)=0x0;
			}
		}*/
	}
}



/*void main()
{ while (1)
	if((*(samp_rdy + 0x3)==0x1)){
		*au_out = *au_in;
		*(samp_rdy + 0x3)=0x0;
	}
}*/