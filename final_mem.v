`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/29/2018 03:08:18 PM
// Design Name: 
// Module Name: aaes
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



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
  
  assign key_in= 128'h0f1571c947d9e8590cb7add6af7f6798;
  assign key_in1= 128'h0f470caf15d9b77f71e8ad67c959d698;
          
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
  

  
  for(i=0;i<9;i=i+1)
  begin
    if(i==1'b0)
      assign plain_split2[i]= plain_split;
    else
      assign plain_split2[i]= mix_colo[i-1];   
    for(k=0;k<16;k=k+1)
    mem1 s_(plain_split2[i][8*k+7:8*k],sub_byte[i][8*k+7:8*k]);
  shift_row sh_(.in(sub_byte[i]),.out(shift_ro[i])); 
  parent_mix pa_(.in(shift_ro[i]),.out(mix_colo_final[i])); 
  assign mix_colo[i]= mix_colo_final[i] ^ round_keys1[128*i+127:128*i];   
     
  end
   
 // last iteration
 for(l=0;l<16;l=l+1)
    mem1 s_1(mix_colo[8][8*l+7:8*l],sub_byte_final[8*l+7:8*l]);
 shift_row sh_1(.in(sub_byte_final),.out(shift_ro_final)); 
 assign cipher= shift_ro_final ^ round_keys1[1279:1152];  
 assign cipher1= {cipher[0:7],cipher[32:39],cipher[64:71],cipher[96:103],
                       cipher[8:15],cipher[40:47],cipher[72:79],cipher[104:111],
                       cipher[16:23],cipher[48:55],cipher[80:87],cipher[112:119],
                       cipher[24:31],cipher[56:63],cipher[88:95],cipher[120:127]};
endmodule


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
    mem1 s_1(temp1[(i/4)-1][8*j+7:j*8],temp2[(i/4)-1][8*j+7:j*8]);
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
  
endmodule  




