module DE0_VGA 
(
	 clk_50, pixel_color, VGA_BUS_R, VGA_BUS_G, VGA_BUS_B, VGA_HS, VGA_VS, X_pix, Y_pix, H_visible, V_visible, pixel_clk, pixel_cnt
);

input		wire				clk_50;

input		wire	[11:0]	pixel_color;

output	reg	[3:0]		VGA_BUS_R;
output	reg	[3:0]		VGA_BUS_G;
output	reg	[3:0]		VGA_BUS_B;

output	reg	[0:0]		VGA_HS;
output	reg	[0:0]		VGA_VS;

output	reg	[10:0]	X_pix;
output	reg	[10:0]	Y_pix;
		
output	reg	[0:0]		H_visible;
output	reg	[0:0]		V_visible;
			
output	reg	[0:0]		pixel_clk;

output	reg	[9:0]		pixel_cnt;

			reg	[10:0]	HS_counter;
			reg	[10:0]	VS_counter;

			wire	[0:0]		vertical_clk;


//1280x1024@60Hz
//http://tinyvga.com/vga-timing/1280x1024@60Hz
parameter HSNC_STRT 		= 48;
parameter HSNC_END  		= HSNC_STRT + 112;
parameter HBCK_PRCH_END = HSNC_END + 248;
parameter HVSBL_END		= HBCK_PRCH_END + 1280;

parameter VSNC_STRT		= 1;
parameter VSNC_END		= VSNC_STRT + 3;
parameter VBCK_PRCH_END	= VSNC_END + 38;
parameter VVSBL_END		= VBCK_PRCH_END + 1024;

assign X_pix 	= (HS_counter - HBCK_PRCH_END) > 0 ? (HS_counter - HBCK_PRCH_END) : 0;
assign Y_pix	= (VS_counter - VBCK_PRCH_END) > 0 ? (VS_counter - VBCK_PRCH_END) : 0;


initial
	begin
		VGA_BUS_R 	<= 4'b0000;
		VGA_BUS_G 	<= 4'b0000;
		VGA_BUS_B 	<= 4'b0000;
		VGA_VS		<= 1'b1;
		VGA_HS		<= 1'b1;
		
		HS_counter	<=	11'b0;
		VS_counter	<= 11'b0;
		
		H_visible	<= 1'b0;
		V_visible	<= 1'b0;
				
		pixel_cnt	<= 1;
		
	end
	
//Display Stuff!
always @(posedge pixel_clk)
	begin
		if((H_visible == 1'b1) && (V_visible == 1'b1))
			begin
				VGA_BUS_R 	<= pixel_color[3:0];
				VGA_BUS_G 	<= pixel_color[7:4];
				VGA_BUS_B 	<= pixel_color[11:8];
			
				pixel_cnt	<= pixel_cnt + 1'b1;
			end
		else
			begin
				pixel_cnt	<= 0;
				VGA_BUS_R 	<= 4'b0000;
				VGA_BUS_G 	<= 4'b0000;
				VGA_BUS_B 	<= 4'b0000;	
			end
	end
	
//Timing for VGA_HS and VGA_VS
always @(posedge pixel_clk)
	begin
		case(HS_counter)
			//Wait for front porch
			HSNC_STRT:						//Start sync.
			begin	
				VGA_HS <= 1'b0;
				H_visible <= H_visible;
				HS_counter <= HS_counter + 1'b1; 
			end
			HSNC_END:							//Sync over.
			begin
				VGA_HS <= 1'b1;
				H_visible <= H_visible;
				HS_counter <= HS_counter + 1'b1; 
			end			
			HBCK_PRCH_END:				//Back porch over. Visable area begin.
			begin
				VGA_HS <= VGA_HS;
				H_visible <= 1'b1;
				HS_counter <= HS_counter + 1'b1; 
			end	
			HVSBL_END:					//Visable area over. Reset counter.
			begin
				VGA_HS <= VGA_HS;
				H_visible <= 1'b0;
				HS_counter <= 1;
				if (VS_counter == VVSBL_END)
					begin
						VS_counter <= 1;
					end
				else
					begin
						VS_counter <= VS_counter + 1'b1;
					end
			end
			default:
			begin
				VGA_HS <= VGA_HS;
				H_visible <= H_visible;
				HS_counter <= HS_counter + 1'b1; 
			end
		endcase
	end
	
always @(posedge pixel_clk)
	begin
		case(VS_counter)
			//Wait for front porch
			VSNC_STRT:					//Start sync.
			begin	
				VGA_VS <= 1'b0;
				V_visible	<= V_visible;
			end
			VSNC_END:					//Sync over.
			begin
				VGA_VS <= 1'b1;
				V_visible	<= V_visible;
			end			
			VBCK_PRCH_END:				//Back porch over. Visable area begin.
			begin
				VGA_VS <= VGA_VS;
				V_visible	<= 1'b1;
			end	
			VVSBL_END:					//Visable area over. Reset counter.
			begin
				VGA_VS <= VGA_VS;
				V_visible	<= 1'b0;
			end
			default
			begin
				VGA_VS <= VGA_VS;
				V_visible	<= V_visible;
			end
		endcase
	end
	
	PLL_PIXEL_CLK pll_inst0
	(
		.inclk0(clk_50),
		.c0(pixel_clk)
	);

		
endmodule
		