
`timescale 1ns / 1ps

module tb_fir_file;

    integer fd;
    integer scan_result;
    integer row_count;

    integer q0, q1, q2, q3;

    initial begin
        row_count = 0;

        // Step 1: Open the input file
        fd = $fopen("03_Data/MF_input_samples.txt", "r");

        if (fd == 0) begin
            $display("ERROR: Could not open input file");
            $finish;
        end

        // Step 2: Read until the end of the file
        while (!$feof(fd)) begin

            scan_result = $fscanf(fd, "%d %d %d %d",
                                  q0, q1, q2, q3);

            // Count only complete rows of four integers
            if (scan_result == 4) begin
                row_count = row_count + 1;

                // Print only the first three rows
                if (row_count <= 3) begin
                    $display("Row %0d: %0d %0d %0d %0d",
                             row_count, q0, q1, q2, q3);
                end
            end
        end

        // Step 3: Close the file
        $fclose(fd);

        // Report the total number of rows
        $display("Loaded %0d rows", row_count);

        $finish;
    end

endmodule
