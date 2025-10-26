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
reg copying_done;
reg [15:0] data;
reg [7:0] counter;
reg pastclk;


dflop clk1(.D(sclk),.clk(clk),.Q(synclock1));
dflop clk2(.D(synclock1),.clk(clk),.Q(synclock2)); 
dflop d1(.D(sdi),.clk(synclock2),.Q(da1));
dflop d2(.D(da1),.clk(synclock2),.Q(da2)); 
dflop cs1(.D(cs),.clk(synclock2),.Q(syncs1));
dflop cs2(.D(syncs1),.clk(synclock2),.Q(syncs2)); 

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        transaction_done <= 1'b0;
        copying_done <= 1'b0;
        data <= 16'b0;
        counter <= 8'b0;
        pastclk <= 1'b0;
    end
    else if(syncs2 == 1'b0) begin
        if(pastclk == 1'b1 && synclock2 == 1'b0) begin
        data <= {data[14:0],da2};
        counter <= counter + 1;
        end
    end
    else if(copying_done == 1'b1)begin
        case (data[14:8]) 
            1:reg1 <= data[7:0];
            2:reg2 <= data[7:0];
            3:reg3 <= data[7:0];
            4:reg4 <= data[7:0];
            5:reg5 <= data[7:0];
        endcase
        transaction_done <= 1'b0;
        copying_done <= 1'b0;
        data <= 16'b0;
        counter <= 8'b0;
    end
    else if(transaction_done == 1'b1) begin
        if(counter == 16 && data[15] == 1 && data[14:8] < 5) begin
        //begin other stuff
        copying_done <= 1'b1;
        end
        else begin
            transaction_done <= 1'b0;
            copying_done <= 1'b0;
            data <= 16'b0;
            counter <= 8'b0;
        end
    end
    else if(syncs2 == 1'b0) begin
        transaction_done <= 1'b0;
    end
    else begin
        transaction_done <= 1'b1;
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