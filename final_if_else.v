// change the state matrix , it is stored columnwise
//conditionally instatiating a module

module vio_aes
(
    input clk
);

    wire [127:0] plain, cipher;
    
    vio_0 vio (.clk(clk), .probe_in0(cipher), .probe_out0(plain));
    AES aes_0 (.plain(plain), .cipher1(cipher));

endmodule

module AES(plain,cipher1);

  

  input[0:127] plain;
  output[127:0] cipher1;
  wire [0:127]cipher;
  
  genvar i,j,k,l;
  integer q;
  wire[1279:0]round_keys; //only temporary round keys, need to generate it by expansion
  reg[1279:0] round_keys1;
  wire[127:0] plain_split1,plain_split;
  wire[127:0]plain_split2[8:0];
 
  //try to use the same variable for storing instaad of one after every operation
  wire[127:0] sub_byte[8:0]; //after  subbyte  operation
  wire[127:0] shift_ro[8:0];
  wire[127:0] shift_ro_final,sub_byte_final;
  wire[127:0] mix_colo_final[8:0]; 
  wire[127:0] mix_colo[8:0];
  
  wire[127:0] key_in,key_in1;
  //assign key_in= 128'h0f470caf15d9b77f71e8ad67c959d698; 
  assign key_in= 128'h0f1571c947d9e8590cb7add6af7f6798;
  assign key_in1= 128'h0f470caf15d9b77f71e8ad67c959d698;
          
  /*arranging plaintext columnwise for processing        
  assign plain_split[0]= {plain[7:0],plain[39:32],plain[71:64],plain[103:96]};
  assign plain_split[1]= {plain[15:8],plain[47:40],plain[79:72],plain[111:104]};
  assign plain_split[2]= {plain[23:16],plain[55:48],plain[87:80],plain[119:112]};
  assign plain_split[3]= {plain[31:24],plain[63:56],plain[95:88],plain[127:120]};
  */
  
  
  assign plain_split1= {plain[0:7],plain[32:39],plain[64:71],plain[96:103],
                       plain[8:15],plain[40:47],plain[72:79],plain[104:111],
                       plain[16:23],plain[48:55],plain[80:87],plain[112:119],
                       plain[24:31],plain[56:63],plain[88:95],plain[120:127]};
  
  key_exp key_(.kin(key_in),.keys_out_final(round_keys));
 
 
  always@(*)
  begin
  for(q=0;q<10;q=q+1)
  begin
  round_keys1[128*q+:128]= {round_keys[120+128*q+:8],round_keys[88+128*q+:8],round_keys[56+128*q+:8],round_keys[24+128*q+:8],
                            round_keys[112+128*q+:8],round_keys[80+128*q+:8],round_keys[48+128*q+:8],round_keys[16+128*q+:8],
            	 	   	         round_keys[104+128*q+:8],round_keys[72+128*q+:8],round_keys[40+128*q+:8],round_keys[8+128*q+:8],
                            round_keys[96+128*q+:8],round_keys[64+128*q+:8],round_keys[32+128*q+:8],round_keys[128*q+:8]};     
    
  end
  end
  
   //1st iteration
  
  
  assign plain_split= plain_split1 ^ key_in1;
  
  /*
  //next 9 iterations
  for(i=0;i<9;i=i+1)
  begin
    for(k=0;k<16;k=k+1)
    s_box s_(.z(plain_split[8*k+7:8*k]),.o(sub_byte[8*k+7:8*k]));
  shift_row sh_(.in(sub_byte),.out(shift_ro)); 
  parent_mix pa_(.in(shift_ro_final),.out(mix_colo_final));  //shouldnt it be  shift_ro
  assign mix_colo= mix_colo_final ^ round_keys1[128*i+127:128*i];   
  end
  */
  
  //to observe individually
  for(i=0;i<9;i=i+1)
  begin
    if(i==1'b0)
      assign plain_split2[i]= plain_split;
    else
      assign plain_split2[i]= mix_colo[i-1];   
    for(k=0;k<16;k=k+1)
    s_box s_(.z(plain_split2[i][8*k+7:8*k]),.o(sub_byte[i][8*k+7:8*k]));
  shift_row sh_(.in(sub_byte[i]),.out(shift_ro[i])); 
  parent_mix pa_(.in(shift_ro[i]),.out(mix_colo_final[i])); 
  assign mix_colo[i]= mix_colo_final[i] ^ round_keys1[128*i+127:128*i];   
     
  end
   
 // last iteration
 for(l=0;l<16;l=l+1)
    s_box s_1(.z(mix_colo[8][8*l+7:8*l]),.o(sub_byte_final[8*l+7:8*l]));
 shift_row sh_1(.in(sub_byte_final),.out(shift_ro_final)); 
 assign cipher= shift_ro_final ^ round_keys1[1279:1152];  
 assign cipher1= {cipher[0:7],cipher[32:39],cipher[64:71],cipher[96:103],
                       cipher[8:15],cipher[40:47],cipher[72:79],cipher[104:111],
                       cipher[16:23],cipher[48:55],cipher[80:87],cipher[112:119],
                       cipher[24:31],cipher[56:63],cipher[88:95],cipher[120:127]};
endmodule


 
/*
module next_state_logic(pres,count,next):
  
  input[1:0] pres;
  input[3:0] count;
  output[1:0] next;
  
  always@(pres)
  begin
    case(pres)
    
    2'b00:  
            begin
            if(count< 10)
              next= 2'b01;  
            else
              next= 2'b00;
            end   
             
    2'b01:  next= 2'b10;
    2'b10:  
            begin
            if(count< 10)
              next= 2'b11;
            else
              next= 2'b00;
            end  
    2'b11:  next=2'b00;
    
    endcase
  end    
endmodule

module state_reg(clk,rst,pres,next)  
  
  input[1:0] pres;
  input clk,rst;
  output[1:0] next;
  
  always@(posedge clk,negedge rst)
  begin
  if(rst==1)
    pres= 2'b00;
  else  
    pres= next;    
  end  
  
module out_logi(pres,out):

  input[1:0] pres;
  output[127:0] out;
  always@(pres)
  begin
    
    
  end  
  
endmodule  
//------------------------
*/

// module ports can't be 2-d arrays

module shift_row(in,out);  //Takes a 128 bit input, outputs a 2-d array of shift_wo operation
  input[127:0] in; 
  output[127:0] out;
     // each element 8 bits, 2d array of such elements
  wire[31:0] temp[0:3];
  //Can save some code here if known how to combine(BIG ENDIAN)
  assign temp[0]= {in[7:0],in[31:24],in[23:16],in[15:8]};
  assign temp[1]= {in[47:40],in[39:32],in[63:56],in[55:48]};
  assign temp[2]= {in[87:80],in[79:72],in[71:64],in[95:88]};
  assign temp[3]= {in[127:120],in[119:112],in[111:104],in[103:96]} ;
  assign out= {temp[3],temp[2],temp[1],temp[0]};
endmodule

module parent_mix(in,out); //Takes input matrix and gives mixed column output

  input[0:127] in;
  output[127:0] out;
  wire[31:0] s0,s1,s2,s3,s0_,s1_,s2_,s3_;
  wire [31:0] temp[3:0];
 /* original order
    {plain[0:7],plain[32:39],plain[64:71],plain[96:103],
     plain[8:15],plain[40:47],plain[72:79],plain[104:111],
     plain[16:23],plain[48:55],plain[80:87],plain[112:119],
     plain[24:31],plain[56:63],plain[88:95],plain[120:127]};
  */
  //changing the row wise input matrix to column wise
  assign s0= {in[0:7],in[32:39],in[64:71],in[96:103]};
  assign s1= {in[8:15],in[40:47],in[72:79],in[104:111]};
  assign s2= {in[16:23],in[48:55],in[80:87],in[112:119]};
  assign s3= {in[24:31],in[56:63],in[88:95],in[120:127]};

  mix_column col1(.in_col(s0),.out_col(s0_));
  mix_column col2(.in_col(s1),.out_col(s1_));
  mix_column col3(.in_col(s2),.out_col(s2_));
  mix_column col4(.in_col(s3),.out_col(s3_));


  assign temp[0]= {s0_[31:24],s1_[31:24],s2_[31:24],s3_[31:24]};
  assign temp[1]= {s0_[23:16],s1_[23:16],s2_[23:16],s3_[23:16]};
  assign temp[2]= {s0_[15:8],s1_[15:8],s2_[15:8],s3_[15:8]};
  assign temp[3]= {s0_[7:0],s1_[7:0],s2_[7:0],s3_[7:0]};

  assign out= {temp[0],temp[1],temp[2],temp[3]};
endmodule


module field_mult(in,flag,out);
  input[7:0] in;
  input flag;
  output reg[7:0] out;
  reg [7:0]in_temp;

  always @(*)
  begin
  if(flag== 1'b0)  //indicates that it is a 2
  begin
    if(in[7]== 1'b0)
      out= (in<< 1'b1);
    else
      out= (in<< 1'b1)^(8'b00011011);
  end

  if(flag==1'b1)  //indicates that it is a 3
  begin
    in_temp=in;

    if(in[7]== 1'b0)
      out= (in_temp<< 1'b1)^ in ;
    else
      out= (in_temp<< 1'b1)^in^(8'b00011011);
  end
  end
endmodule

module mix_column(in_col,out_col); // a single column as input gives the mixed column transformation
  input[31:0] in_col;
  output[31:0] out_col;
  wire[31:0] temp_;
  wire[31:0] s0_wire[3:0];



  //1_1st ele
  field_mult col1_1_1(in_col[31:24],0,s0_wire[0][31:24]);
  field_mult col1_1_2(in_col[23:16],1,s0_wire[0][23:16]);
  assign s0_wire[0][15:0]= in_col[15:0];
  assign temp_[31:24]= s0_wire[0][31:24] ^ s0_wire[0][23:16] ^ s0_wire[0][15:8] ^ s0_wire[0][7:0];

  //1_2nd ele
  field_mult col1_2_2(in_col[23:16],0,s0_wire[1][23:16]);
  field_mult col1_2_3(in_col[15:8],1,s0_wire[1][15:8]);
  assign s0_wire[1][31:24]= in_col[31:24];
  assign s0_wire[1][7:0]= in_col[7:0];
  assign temp_[23:16]= s0_wire[1][31:24] ^ s0_wire[1][23:16] ^ s0_wire[1][15:8] ^ s0_wire[1][7:0];
  //1_3ele
  field_mult col1_3_3(in_col[15:8],0,s0_wire[2][15:8]);
  field_mult col1_3_4(in_col[7:0],1,s0_wire[2][7:0]);
  assign s0_wire[2][31:24]= in_col[31:24];
  assign s0_wire[2][23:16]= in_col[23:16];
  assign temp_[15:8]= s0_wire[2][31:24] ^ s0_wire[2][23:16] ^ s0_wire[2][15:8] ^ s0_wire[2][7:0];

  //1_4th ele
  field_mult col1_4_4(in_col[7:0],0,s0_wire[3][7:0]);
  field_mult col1_4_1(in_col[31:24],1,s0_wire[3][31:24]);
  assign s0_wire[3][23:8]= in_col[23:8];
  assign temp_[7:0]= s0_wire[3][31:24] ^ s0_wire[3][23:16] ^ s0_wire[3][15:8] ^ s0_wire[3][7:0];

  assign out_col= temp_;

endmodule



/*
module g_func(inp,outp,key_index);
  input[31:0] inp;
  input en;
  input [4:0] key_index;
  output[31:0] outp;
  wire[31:0] outp_temp;
  wire[31:0] temp1,temp2;
  wire[8:0] rcon[9:0];

  assign rcon[0]= 8'h01;
  assign rcon[1]= 8'h02;
  assign rcon[2]= 8'h04;
  assign rcon[3]= 8'h08;
  assign rcon[4]= 8'h10;
  assign rcon[5]= 8'h20;
  assign rcon[6]= 8'h40;
  assign rcon[7]= 8'h80;
  assign rcon[8]= 8'h1b;
  assign rcon[9]= 8'h36;
  
  
  
  assign temp1={inp[23:16],inp[15:8],inp[7:0],inp[31:24]};
  
  
  genvar i;
  generate for (i = 0; i < 4; i = i + 1) begin
  s_box a(temp1[8*i+7:i*8],temp2[8*i+7:i*8]);
  assign outp_temp[8*i+7:i*8]= temp2[8*i+7:i*8];
  end endgenerate
   
  
 
  
  assign outp[31:24]= outp_temp[31:24] ^ rcon[key_index];
  assign outp[23:0]= outp_temp[23:0]; 
  */  
//--------------------------------------------- 
  


module key_exp(kin,keys_out_final);
  
  input[127:0] kin;
  wire[1279:0] keys_out;
  output[1279:0] keys_out_final;
  wire[127:0] keys[10:0];
  wire[31:0] word[43:0];
  wire[31:0] outp_temp[9:0];
  wire[31:0] temp1[9:0];
  wire[31:0] temp2[9:0];
  wire[8:0] rcon[9:0];
  


  genvar i,j;
  integer q;

  
  assign word[0]= kin[127:96];
  assign word[1]= kin[95:64];
  assign word[2]= kin[63:32];
  assign word[3]= kin[31:0];
  
  
  //assigning rcon values
  assign rcon[0]= 8'h01;
  assign rcon[1]= 8'h02;
  assign rcon[2]= 8'h04;
  assign rcon[3]= 8'h08;
  assign rcon[4]= 8'h10;
  assign rcon[5]= 8'h20;
  assign rcon[6]= 8'h40;
  assign rcon[7]= 8'h80;
  assign rcon[8]= 8'h1b;
  assign rcon[9]= 8'h36;
  
  generate  for(i=4;i<44;i=i+1)
  begin
    
  if((i%4)==0)
  begin  
  //g_func g1(word[i-1],word[i],(i/4)-1); // try to remove division 
  
    assign temp1[(i/4)-1]={word[i-1][23:16],word[i-1][15:8],word[i-1][7:0],word[i-1][31:24]};
  
  
    for (j = 0; j < 4; j = j + 1) 
    begin
    s_box s_1(.z(temp1[(i/4)-1][8*j+7:j*8]),.o(temp2[(i/4)-1][8*j+7:j*8]));
    assign outp_temp[(i/4)-1][8*j+7:j*8]= temp2[(i/4)-1][8*j+7:j*8];
    end 
   
    assign word[i][31:24]= (outp_temp[(i/4)-1][31:24] ^ rcon[(i/4)-1]) ^word[i-4][31:24] ;
    assign word[i][23:0]= outp_temp[(i/4)-1][23:0]^ word[i-4][23:0]; 
  end  
//--------------------------------------------- 
 else   
    assign word[i]= word[i-1]^word[i-4];
   
  if(i%4==3 )
    begin
    assign keys[(i/4)]= {word[i-3],word[i-2],word[i-1],word[i]} ; //try to remove divide operator 
    assign keys_out_final[128*((i/4)-1)+127:128*((i/4)-1)]= keys[(i/4)];
    end    
     
  end 
  endgenerate
  
  /* 
   
  always@(*)
  begin
  for(q=0;q<10;q=q+1)
  begin
    keys_out_final= {keys_out[7+:128*q],keys_out[39+:32+128*q],keys_out[71+:64+128*q],keys_out[103+:96+128*q],
                       keys_out[15+128*q:8+128*q],keys_out[47+128*q:40+128*q],keys_out[79+128*q:72+128*q],keys_out[111+128*q:104+128*q],
                       keys_out[23+128*q:16+128*q],keys_out[55+128*q:48+128*q],keys_out[87+128*q:80+128*q],keys_out[119+128*q:112+128*q],
                       keys_out[31+128*q:24+128*q],keys_out[63+128*q:56+128*q],keys_out[95+128*q:88+128*q],keys_out[127+128*q:120+128*q]};     
    
  end
    
  
    
  end 
  */ 
endmodule  


// you probably do not need a module for this, define the parameter and use it.

module s_box(z,o); // make a ROM implementation like harish said.

  input[7:0] z;
  output reg[7:0] o;
  
  
  parameter[23:0] s_bo={8'h88,8'h99,8'h7a};
  

  
  //if statements must be inside an always block
  //y axis taken as msb x axis is lsb of the byte input
  always@(*)
  begin

  if(z== 8'h00)
     o= 8'h63;
  else if(z== 8'h01)
     o= 8'h7c;
  else if(z== 8'h02)
     o= 8'h77;
  else if(z== 8'h03)
     o= 8'h7b;
  else if(z== 8'h04)
     o= 8'hf2;
  else if(z== 8'h05)
     o= 8'h6b;
  else if(z== 8'h06)
     o= 8'h6f;
  else if(z== 8'h07)
     o= 8'hc5;
  else if(z== 8'h08)
     o= 8'h30;
  else if(z== 8'h09)
     o= 8'h01;
  else if(z== 8'h0a)
     o= 8'h67;
  else if(z== 8'h0b)
     o= 8'h2b;
  else if(z== 8'h0c)
     o= 8'hfe;
  else if(z== 8'h0d)
     o= 8'hd7;
  else if(z== 8'h0e)
     o= 8'hab;
  else if(z== 8'h0f)
     o= 8'h76;


  else if(z== 8'h10)
     o= 8'hca;
  else if(z== 8'h11)
     o= 8'h82;
  else if(z== 8'h12)
     o= 8'hc9;
  else if(z== 8'h13)
     o= 8'h7d;
  else if(z== 8'h14)
     o= 8'hfa;
  else if(z== 8'h15)
     o= 8'h59;
  else if(z== 8'h16)
     o= 8'h47;
  else if(z== 8'h17)
     o= 8'hf0;
  else if(z== 8'h18)
     o= 8'had;
  else if(z== 8'h19)
     o= 8'hd4;
  else if(z== 8'h1a)
     o= 8'ha2;
  else if(z== 8'h1b)
     o= 8'haf;
  else if(z== 8'h1c)
     o= 8'h9c;
  else if(z== 8'h1d)
     o= 8'ha4;
  else if(z== 8'h1e)
     o= 8'h72;
  else if(z== 8'h0f)
     o= 8'hc0;

  else if(z== 8'h20)
     o= 8'hb7;
  else if(z== 8'h21)
     o= 8'hfd;
  else if(z== 8'h22)
     o= 8'h93;
  else if(z== 8'h23)
     o= 8'h26;
  else if(z== 8'h24)
     o= 8'h36;
  else if(z== 8'h25)
     o= 8'h3f;
  else if(z== 8'h26)
     o= 8'hf7;
  else if(z== 8'h27)
     o= 8'hcc;
  else if(z== 8'h28)
     o= 8'h34;
  else if(z== 8'h29)
     o= 8'ha5;
  else if(z== 8'h2a)
     o= 8'he5;
  else if(z== 8'h2b)
     o= 8'hf1;
  else if(z== 8'h2c)
     o= 8'h71;
  else if(z== 8'h2d)
     o= 8'hd8;
  else if(z== 8'h2e)
     o= 8'h31;
  else if(z== 8'h2f)
     o= 8'h15;

  else if(z== 8'h30)
     o= 8'h04;
  else if(z== 8'h31)
     o= 8'hc7;
  else if(z== 8'h32)
     o= 8'h23;
  else if(z== 8'h33)
     o= 8'hc3;
  else if(z== 8'h34)
     o= 8'h18;
  else if(z== 8'h35)
     o= 8'h96;
  else if(z== 8'h36)
     o= 8'h05;
  else if(z== 8'h37)
     o= 8'h9a;
  else if(z== 8'h38)
     o= 8'h07;
  else if(z== 8'h39)
     o= 8'h12;
  else if(z== 8'h3a)
     o= 8'h80;
  else if(z== 8'h3b)
     o= 8'he2;
  else if(z== 8'h3c)
     o= 8'heb;
  else if(z== 8'h3d)
     o= 8'h27;
  else if(z== 8'h3e)
     o= 8'hb2;
  else if(z== 8'h3f)
     o= 8'h75;


  else if(z== 8'h40)
     o= 8'h09;
  else if(z== 8'h41)
     o= 8'h83;
  else if(z== 8'h42)
     o= 8'h2c;
  else if(z== 8'h43)
     o= 8'h1a;
  else if(z== 8'h44)
     o= 8'h1b;
  else if(z== 8'h45)
     o= 8'h6e;
  else if(z== 8'h46)
     o= 8'h5a;
  else if(z== 8'h47)
     o= 8'ha0;
  else if(z== 8'h48)
     o= 8'h52;
  else if(z== 8'h49)
     o= 8'h3b;
  else if(z== 8'h4a)
     o= 8'hd6;
  else if(z== 8'h4b)
     o= 8'hb3;
  else if(z== 8'h4c)
     o= 8'h29;
  else if(z== 8'h4d)
     o= 8'he3;
  else if(z== 8'h4e)
     o= 8'h 2f;
  else if(z== 8'h4f)
     o= 8'h84;

  else if(z== 8'h50)
     o= 8'h53;
  else if(z== 8'h51)
     o= 8'hd1;
  else if(z== 8'h52)
     o= 8'h00;
  else if(z== 8'h53)
     o= 8'hed;
  else if(z== 8'h54)
     o= 8'h20;
  else if(z== 8'h55)
     o= 8'hfc;
  else if(z== 8'h56)
     o= 8'hb1;
  else if(z== 8'h57)
     o= 8'h5b;
  else if(z== 8'h58)
     o= 8'h6a;
  else if(z== 8'h59)
     o= 8'hcb;
  else if(z== 8'h5a)
     o= 8'hbe;
  else if(z== 8'h5b)
     o= 8'h39;
  else if(z== 8'h5c)
     o= 8'h4a;
  else if(z== 8'h5d)
     o= 8'h4c;
  else if(z== 8'h5e)
     o= 8'h58;
  else if(z== 8'h5f)
     o= 8'hcf;

  else if(z== 8'h60)
     o= 8'hd0;
  else if(z== 8'h61)
     o= 8'hef;
  else if(z== 8'h62)
     o= 8'haa;
  else if(z== 8'h63)
     o= 8'hfb;
  else if(z== 8'h64)
     o= 8'h43;
  else if(z== 8'h65)
     o= 8'h4d;
  else if(z== 8'h66)
     o= 8'h33;
  else if(z== 8'h67)
     o= 8'h85;
  else if(z== 8'h68)
     o= 8'h45;
  else if(z== 8'h69)
     o= 8'hf9;
  else if(z== 8'h6a)
     o= 8'h02;
  else if(z== 8'h6b)
     o= 8'h7f;
  else if(z== 8'h6c)
     o= 8'h50;
  else if(z== 8'h6d)
     o= 8'h3c;
  else if(z== 8'h6e)
     o= 8'h9f;
  else if(z== 8'h6f)
     o= 8'ha8;

  else if(z== 8'h70)
     o= 8'h51;
  else if(z== 8'h71)
     o= 8'ha3;
  else if(z== 8'h72)
     o= 8'h40;
  else if(z== 8'h73)
     o= 8'h8f;
  else if(z== 8'h74)
     o= 8'h92;
  else if(z== 8'h75)
     o= 8'h9d;
  else if(z== 8'h76)
     o= 8'h38;
  else if(z== 8'h77)
     o= 8'hf5;
  else if(z== 8'h78)
     o= 8'hbc;
  else if(z== 8'h79)
     o= 8'hb6;
  else if(z== 8'h7a)
     o= 8'hda;
  else if(z== 8'h7b)
     o= 8'h21;
  else if(z== 8'h7c)
     o= 8'h10;
  else if(z== 8'h7d)
     o= 8'hff;
  else if(z== 8'h7e)
     o= 8'hf3;
  else if(z== 8'h7f)
     o= 8'hd2;

  else if(z== 8'h80)
     o= 8'hcd;
  else if(z== 8'h81)
     o= 8'h0c;
  else if(z== 8'h82)
     o= 8'h13;
  else if(z== 8'h83)
     o= 8'hec;
  else if(z== 8'h84)
     o= 8'h5f;
  else if(z== 8'h85)
     o= 8'h97;
  else if(z== 8'h86)
     o= 8'h44;
  else if(z== 8'h87)
     o= 8'h17;
  else if(z== 8'h88)
     o= 8'hc4;
  else if(z== 8'h89)
     o= 8'ha7;
  else if(z== 8'h8a)
     o= 8'h7e;
  else if(z== 8'h8b)
     o= 8'h3d;
  else if(z== 8'h8c)
     o= 8'h64;
  else if(z== 8'h8d)
     o= 8'h5d;
  else if(z== 8'h8e)
     o= 8'h19;
  else if(z== 8'h8f)
     o= 8'h73;

  else if(z== 8'h90)
     o= 8'h60;
  else if(z== 8'h91)
     o= 8'h81;
  else if(z== 8'h92)
     o= 8'h4f;
  else if(z== 8'h93)
     o= 8'hdc;
  else if(z== 8'h94)
     o= 8'h22;
  else if(z== 8'h95)
     o= 8'h2a;
  else if(z== 8'h96)
     o= 8'h90;
  else if(z== 8'h97)
     o= 8'h88;
  else if(z== 8'h98)
     o= 8'h46;
  else if(z== 8'h99)
     o= 8'hee;
  else if(z== 8'h9a)
     o= 8'hb8;
  else if(z== 8'h9b)
     o= 8'h14;
  else if(z== 8'h9c)
     o= 8'hde;
  else if(z== 8'h9d)
     o= 8'h5e;
  else if(z== 8'h9e)
     o= 8'h0b;
  else if(z== 8'h9f)
     o= 8'hdb;

  else if(z== 8'ha0)
     o= 8'he0;
  else if(z== 8'ha1)
     o= 8'h32;
  else if(z== 8'ha2)
     o= 8'h3a;
  else if(z== 8'ha3)
     o= 8'h0a;
  else if(z== 8'ha4)
     o= 8'h49;
  else if(z== 8'ha5)
     o= 8'h06;
  else if(z== 8'ha6)
     o= 8'h24;
  else if(z== 8'ha7)
     o= 8'h5c;
  else if(z== 8'ha8)
     o= 8'hc2;
  else if(z== 8'ha9)
     o= 8'hd3;
  else if(z== 8'haa)
     o= 8'hac;
  else if(z== 8'hab)
     o= 8'h62;
  else if(z== 8'hac)
     o= 8'h91;
  else if(z== 8'had)
     o= 8'h95;
  else if(z== 8'hae)
     o= 8'he4;
  else if(z== 8'haf)
     o= 8'h79;

  else if(z== 8'hb0)
     o= 8'he7;
  else if(z== 8'hb1)
     o= 8'hc8;
  else if(z== 8'hb2)
     o= 8'h37;
  else if(z== 8'hb3)
     o= 8'h6d;
  else if(z== 8'hb4)
     o= 8'h8d;
  else if(z== 8'hb5)
     o= 8'hd5;
  else if(z== 8'hb6)
     o= 8'h4e;
  else if(z== 8'hb7)
     o= 8'ha9;
  else if(z== 8'hb8)
     o= 8'h6c;
  else if(z== 8'hb9)
     o= 8'h56;
  else if(z== 8'hba)
     o= 8'hf4;
  else if(z== 8'hbb)
     o= 8'hea;
  else if(z== 8'hbc)
     o= 8'h65;
  else if(z== 8'hbd)
     o= 8'h7a;
  else if(z== 8'hbe)
     o= 8'hae;
  else if(z== 8'hbf)
     o= 8'h08;

  else if(z== 8'hc0)
     o= 8'hba;
  else if(z== 8'hc1)
     o= 8'h78;
  else if(z== 8'hc2)
     o= 8'h25;
  else if(z== 8'hc3)
     o= 8'h2e;
  else if(z== 8'hc4)
     o= 8'h1c;
  else if(z== 8'hc5)
     o= 8'ha6;
  else if(z== 8'hc6)
     o= 8'hb4;
  else if(z== 8'hc7)
     o= 8'hc6;
  else if(z== 8'hc8)
     o= 8'he8;
  else if(z== 8'hc9)
     o= 8'hdd;
  else if(z== 8'hca)
     o= 8'h74;
  else if(z== 8'hcb)
     o= 8'h1f;
  else if(z== 8'hcc)
     o= 8'h4b;
  else if(z== 8'hcd)
     o= 8'hbd;
  else if(z== 8'hce)
     o= 8'h8b;
  else if(z== 8'hcf)
     o= 8'h8a;

  else if(z== 8'hd0)
     o= 8'h70;
  else if(z== 8'hd1)
     o= 8'h3e;
  else if(z== 8'hd2)
     o= 8'hb5;
  else if(z== 8'hd3)
     o= 8'h66;
  else if(z== 8'hd4)
     o= 8'h48;
  else if(z== 8'hd5)
     o= 8'h03;
  else if(z== 8'hd6)
     o= 8'hf6;
  else if(z== 8'hd7)
     o= 8'h0e;
  else if(z== 8'hd8)
     o= 8'h61;
  else if(z== 8'hd9)
     o= 8'h35;
  else if(z== 8'hda)
     o= 8'h57;
  else if(z== 8'hdb)
     o= 8'hb9;
  else if(z== 8'hdc)
     o= 8'h86;
  else if(z== 8'hdd)
     o= 8'hc1;
  else if(z== 8'hde)
     o= 8'h1d;
  else if(z== 8'hdf)
     o= 8'h9e;

  else if(z== 8'he0)
     o= 8'he1;
  else if(z== 8'he1)
     o= 8'hf8;
  else if(z== 8'he2)
     o= 8'h98;
  else if(z== 8'he3)
     o= 8'h11;
  else if(z== 8'he4)
     o= 8'h69;
  else if(z== 8'he5)
     o= 8'hd9;
  else if(z== 8'he6)
     o= 8'h8e;
  else if(z== 8'he7)
     o= 8'h94;
  else if(z== 8'he8)
     o= 8'h9b;
  else if(z== 8'he9)
     o= 8'h1e;
  else if(z== 8'hea)
     o= 8'h87;
  else if(z== 8'heb)
     o= 8'he9;
  else if(z== 8'hec)
     o= 8'hce;
  else if(z== 8'hed)
     o= 8'h55;
  else if(z== 8'hee)
     o= 8'h28;
  else if(z== 8'hef)
     o= 8'hdf;

  else if(z== 8'hf0)
     o= 8'h8c;
  else if(z== 8'hf1)
     o= 8'ha1;
  else if(z== 8'hf2)
     o= 8'h89;
  else if(z== 8'hf3)
     o= 8'h0d;
  else if(z== 8'hf4)
     o= 8'hbf;
  else if(z== 8'hf5)
     o= 8'he6;
  else if(z== 8'hf6)
     o= 8'h42;
  else if(z== 8'hf7)
     o= 8'h68;
  else if(z== 8'hf8)
     o= 8'h41;
  else if(z== 8'hf9)
     o= 8'h99;
  else if(z== 8'hfa)
     o= 8'h2d;
  else if(z== 8'hfb)
     o= 8'h0f;
  else if(z== 8'hfc)
     o= 8'hb0;
  else if(z== 8'hfd)
     o= 8'h54;
  else if(z== 8'hfe)
     o= 8'hbb;
  else
     o= 8'h16;
  end
endmodule


