// APB RAM
module apb_slave_memory(PCLK,PRESET,PADDR,PWDATA,PWRITE,PSEL,PENABLE,PRDATA,PREADY,PSLVERR);
  
  input logic PCLK,PRESET,PWRITE,PSEL,PENABLE;
  input logic  [31:0] PADDR,PWDATA;
  output logic [31:0] PRDATA;
  output logic PREADY,PSLVERR;
  
  //Memory
  reg [31:0] MEM [32];
  
  typedef enum {IDLE = 0,SETUP=1,ACCESS=2,TRANSFER=3} state_type;
 
  state_type state = IDLE; 
  
  always@(posedge PCLK)
    begin
      if(PRESET == 1'b0) //active low
        begin
          state <= IDLE;
          PRDATA <= 32'h0000_0000;
          PREADY <= 1'b0;
          PSLVERR <= 1'b0;

          for(int i = 0; i < 32; i++) 
              MEM[i] <= 0;
       	end 
      else 
        begin
    
      case(state)
      IDLE : 
      begin
        PRDATA <= 32'h00000000;
        PREADY <= 1'b0;
        PSLVERR <= 1'b0;
        state   <= SETUP;
      end
      
      SETUP: ///start of transaction
      begin
        if(PSEL == 1'b1)
             state <= ACCESS;
           else
             state <= SETUP;
          
      end
        
      ACCESS: 
      begin 
        if(PWRITE && PENABLE) //Write transaction
          begin
            if(PADDR < 32) 
              begin
                MEM[PADDR] <= PWDATA;
              	state <= TRANSFER;
              	PSLVERR <= 1'b0;
              	PREADY <= 1'b1;
              end
            
            else 
              begin
                state <= TRANSFER;
                PREADY <= 1'b1;
                PSLVERR <= 1'b1;
              end
          end
        
        else if (!PWRITE && PENABLE) //Read transaction
            begin
              if(PADDR < 32) 
              begin
                PRDATA <= MEM[PADDR];
              	state <= TRANSFER;
              	PREADY <= 1'b1;
             	PSLVERR <= 1'b0;
              end
              
              else 
                begin
                  state <= TRANSFER;
                  PREADY <= 1'b1;
                  PSLVERR <= 1'b1;
                  PRDATA <= 32'hxxxxxxxx;
                  end
          end
        
        else
           state <= SETUP;
       end  
        
        TRANSFER: begin
          state <= SETUP;
          PREADY <= 1'b0;
          PSLVERR <= 1'b0;
        end
            
      default : state <= IDLE;
   
      endcase
      
    end
  end
endmodule
