`default_nettype none



module spi (  
    input clk, sclk, sdi, cs, rst_n, 
    output sdo,
    output reg [7:0] reg1,
    output reg [7:0] reg2,
    output reg [7:0] reg3,
    output reg [7:0] reg4,
    output reg [7:0] reg5

    
);
wire synclock1;
wire synclock2;
wire da1;
wire da2;
wire syncs1;
wire syncs2;
reg transaction_done;
reg checking_done;
reg sampling_now;   
reg [15:0] data;
reg [7:0] counter;
reg pastclk;
assign sdo = 1'b0;

dflop clk1(.D(sclk),.clk(clk),.Q(synclock1));
specialdflop clk2(.D(synclock1),.clk(clk),.Q(synclock2), .past(pastclk)); 
dflop d1(.D(sdi),.clk(synclock2),.Q(da1));
dflop d2(.D(da1),.clk(synclock2),.Q(da2)); 
dflop cs1(.D(cs),.clk(synclock2),.Q(syncs1));
dflop cs2(.D(syncs1),.clk(synclock2),.Q(syncs2)); 

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        //set all regs back to beginning values
        transaction_done <= 1'b0;
        checking_done <= 1'b0;
        data <= 16'b0;
        counter <= 8'b0;
        sampling_now <= 1'b0;
        reg1 <= 8'b0;
        reg2 <= 8'b0;
        reg3 <= 8'b0;
        reg4 <= 8'b0;
        reg5 <= 8'b0;
    end
    else if(checking_done == 1'b1)begin
        //after data analyzed, copy it into the registers
        case (data[14:8]) 
            0:reg1 <= data[7:0];
            1:reg2 <= data[7:0];
            2:reg3 <= data[7:0];
            3:reg4 <= data[7:0];
            4:reg5 <= data[7:0];
        endcase
        //soft reset
        transaction_done <= 1'b0;
        checking_done <= 1'b0;
        data <= 16'b0;
        counter <= 8'b0;
        sampling_now <= 1'b0;
    end
    else if(transaction_done == 1'b1) begin
        //check the data
        if(counter == 16 && data[15] == 1 && data[14:8] < 5) begin
            //confirms to let copying happen
            checking_done <= 1'b1;
        end
        else begin
            //if data is not formatted right, let go of it, soft reset
            transaction_done <= 1'b0;
            checking_done <= 1'b0;
            data <= 16'b0;
            counter <= 8'b0;
            sampling_now <= 1'b0;
        end
    end
    else if(sampling_now == 1'b1 && syncs2 == 1'b0 && pastclk == 1'b1 && synclock2 == 1'b0) begin
        data <= {data[14:0],da2};
        counter <= counter + 1;
    end

    else if(syncs2 == 1'b1 && sampling_now == 1'b1) begin
        sampling_now <= 1'b0;
        transaction_done <= 1'b1;
    end
    else if(syncs2 == 1'b0) begin
        //checks if line is low, to begin taking in data
        sampling_now <= 1'b1;
    end
    
    
end


endmodule

module dflop (
    input  D,     
    input clk,    
    output reg Q
);
always @(posedge clk) begin
    Q <= D;
end
    
endmodule


module specialdflop (
    input  D,     
    input clk,    
    output reg Q,
    output reg past
);
always @(posedge clk) begin
    past <= Q;
    Q <= D;
end
    
endmodule