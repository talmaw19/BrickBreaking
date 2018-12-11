-- Listing 13.3
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity bouncing_box is
   port(
      clk, reset, BTNL, BTNR,BTNU,BTND: in std_logic;
      hsync, vsync: out  std_logic;
      red: out std_logic_vector(3 downto 0);
      green: out std_logic_vector(3 downto 0);
      blue: out std_logic_vector(3 downto 0)           
   );
end bouncing_box;

architecture bouncing_box of bouncing_box is
   signal pixel_x, pixel_y: std_logic_vector(9 downto 0);
   signal video_on, pixel_tick: std_logic;
   signal red_reg, red_next: std_logic_vector(3 downto 0) := (others => '0');
   signal green_reg, green_next: std_logic_vector(3 downto 0) := (others => '0');
   signal blue_reg, blue_next: std_logic_vector(3 downto 0) := (others => '0'); 
   signal btn_l, btn_r, btn_u,btn_d: std_logic;  -- synchronized buttons
   
   ------------ BOX VARIABLES-------- 
   signal box_xl, box_yt, box_xr, box_yb : integer := 0; 
   signal dir_x, dir_y : integer := 1;  
   signal x, y, next_x, next_y : integer := 0; 
   signal update_pos : std_logic := '0';  
   constant slidebar_speed : integer := 5;
   constant default_box_speed : integer := 3;

  
   
   ------------ SLIDEBAR VARIABLES-------- 
   signal xS, yS, next_xS, next_yS : integer := 0; 
   signal slidebar_xl, slidebar_yt, slidebar_xr, slidebar_yb : integer:= 0;
   signal dir_xS, dir_yS : integer := 1;

    
   ------------ BRICK VARIABLES-------- 
    signal brick1_xl, brick1_yt, brick1_xr, brick1_yb : integer:= 0;
    signal brick2_xl, brick2_yt, brick2_xr, brick2_yb : integer:= 0;
    signal brick3_xl, brick3_yt, brick3_xr, brick3_yb : integer:= 0;
    signal brick4_xl, brick4_yt, brick4_xr, brick4_yb : integer:= 0;
    signal brick5_xl, brick5_yt, brick5_xr, brick5_yb : integer:= 0;
    signal brick6_xl, brick6_yt, brick6_xr, brick6_yb : integer:= 0;
    signal brick7_xl, brick7_yt, brick7_xr, brick7_yb : integer:= 0;
    signal brick8_xl, brick8_yt, brick8_xr, brick8_yb : integer:= 0;
   -------score ------
   signal player_score : integer range 0 to 10:= 0;
   signal resetBrick1 : integer :=0;
   signal resetGame, resetBrick2,resetBrick3 ,resetBrick4,resetBrick5, resetBrick6, resetBrick7,resetBrick8  : integer := 0;
  
   
   
begin
   -- instantiate VGA sync circuit
   vga_sync_unit: entity work.vga_sync
    port map(clk=>clk, reset=>reset, hsync=>hsync,
               vsync=>vsync, video_on=>video_on,
               pixel_x=>pixel_x, pixel_y=>pixel_y,
               p_tick=>pixel_tick);
               
    -- synchronize input buttons
    sync_l: entity work.synchronizer port map( clk=>clk, a=>BTNL, b=>btn_l );
    sync_r: entity work.synchronizer port map( clk=>clk, a=>BTNR, b=>btn_r );
         
       ------------ BOX POSITIOIN-------- 
       
        box_xl <= x;  
        box_yt <= y;
        box_xr <= x + 10;
        box_yb <= y + 10;  

       ------------ SLIDE BAR POSITIOIN-------- 
     
        slidebar_xl <= xS;
        slidebar_yt <=  450;
        slidebar_xr <=  xS+ 55; 
        slidebar_yb <= yS + 20;     
        

      ------------ bricks POSITIOIN-------- 
        
        brick1_xl <= 300;  
        brick1_yt <= 100;
        brick1_xr <= brick1_xl + 50;
        brick1_yb <= brick1_yt + 20;
        
        brick2_xl <= 250;  
        brick2_yt <= 150;
        brick2_xr <= brick2_xl + 50;
        brick2_yb <= brick2_yt + 20;
        
        brick3_xl <= 350;  
        brick3_yt <= 150;
        brick3_xr <= brick3_xl + 50;
        brick3_yb <= brick3_yt + 20;
        
        brick4_xl <= 200;  
        brick4_yt <= 200;
        brick4_xr <= brick4_xl + 50;
        brick4_yb <= brick4_yt + 20;
        
        brick5_xl <= 300;  
        brick5_yt <= 200;
        brick5_xr <= brick5_xl + 50;
        brick5_yb <= brick5_yt + 20;
        
        brick6_xl <= 400;  
        brick6_yt <= 200;
        brick6_xr <= brick6_xl + 50;
        brick6_yb <= brick6_yt + 20;
        
        brick7_xl <= 250;  
        brick7_yt <= 250;
        brick7_xr <= brick7_xl + 50;
        brick7_yb <= brick7_yt + 20;
        
        brick8_xl <= 350;  
        brick8_yt <= 250;
        brick8_xr <= brick8_xl + 50;
        brick8_yb <= brick8_yt + 20; 
           
    
    -- process to generate update position signal
    process ( video_on )
        variable counter : integer := 0;
    begin
        if rising_edge(video_on) then
            counter := counter + 1;
            if (counter > 120 ) then --and (resetGame = 0)then  --
                counter := 0;
                update_pos <= '1';
            else
                update_pos <= '0';
              
            end if;
         end if;
    end process;
    
---------------- BOX X & Y DIRECTION ------------------

	-- the MUX that computes the next value of x. Anything that can affect
	-- x must be computed within this mux since a signal can only have one driver
	-- compute collision in x or change direction if btn_r or btn_l is pressed
	process ( btn_r, btn_l, dir_x, dir_y, clk, box_xr, box_xl, box_yt, box_yb, slidebar_xr,slidebar_xl,slidebar_yb,slidebar_yt, dir_xS, dir_yS, brick1_xl, brick1_yt, brick1_xr, brick1_yb,
       brick2_xl, brick2_yt, brick2_xr, brick2_yb,brick3_xl, brick3_yt, brick3_xr, brick3_yb ,brick4_xl, brick4_yt, brick4_xr, brick4_yb , brick5_xl, brick5_yt, brick5_xr, brick5_yb ,
       brick6_xl, brick6_yt, brick6_xr, brick6_yb,brick7_xl, brick7_yt, brick7_xr, brick7_yb, brick8_xl, brick8_yt, brick8_xr, brick8_yb,resetGame, resetBrick1, resetBrick2,resetBrick3 ,resetBrick4,resetBrick5, resetBrick6, resetBrick7,resetBrick8 )
	begin
        if rising_edge(clk) then 
        ---------------- BOX X & Y DIRECTION ------------------
          if (box_xr > 639) and (dir_x = 1) then
                        dir_x <= -1;
                        x <= 539;                
                    elsif (box_xl < 1) and (dir_x = -1) then
                        dir_x <= 1;   
                        x <= 0;                
                    else 
                        dir_x <= dir_x;
                        x <= next_x;
                    end if;
                   
                if (box_yb > 479) and (dir_y = 1) then
                    dir_y <= -1;
                    y <= 379;
                elsif (box_yt < 1) and (dir_y = -1) then
                    dir_y <= 1;   
                    y <= 0;     
                else 
                    dir_y <= dir_y;
                    y <= next_y;
                end if;
                
            ---------------- SLIDEBAR X & Y DIRECTION ------------------
             if (slidebar_xr > 620) and (dir_xS = 1) then
                  dir_xS <= -1;
                  xS <= 558;                
              elsif (slidebar_xl < 1) and (dir_xS = -1) then
                  dir_xS <= 1;   
                  xS <= 0;                
              elsif ( btn_r = '1' ) then 
                  dir_xS <= 1;
                  xS <= next_xS;
              elsif ( btn_l = '1' ) then 
                 dir_xS <= -1;
                 xS <= next_xS;
              else 
                 dir_xS <= 0;
                 xS <= next_xS;
              end if;
                
             if (slidebar_yb > 479) and (dir_yS = 1) then
                    dir_yS <= -1;
                    yS <= 379;
                elsif (slidebar_yt < 1) and (dir_yS = -1) then
                    dir_yS <= 1;   
                    yS <= 0;     
                else 
                    dir_yS <= dir_yS;
                   yS <= next_yS;
                end if;   
                
           --- COLLISION CHECKING FOR HITTING THE SLIDEBAR ----
           --- IF THE BOTTOM OF THE BOX IS GREATER THAN OR EQUAL TO THE TOP OF THE SLIDEBAR THEN CHANGE THE DIRECTION OF THE BALL IN THE Y DIRECTION 
             
               if ((box_yb >= slidebar_yt) and (box_xr >= slidebar_xl) and (box_xl <= slidebar_xr) ) then --and (box_yt <= slidebar_yb)
                 dir_y <= -1 ; 
                 -- BRICK TOP
                 end if; 
               ------- THIS HERE CHECKS THE COLLISON FOR THE BRICK 1, ONCE THE BOX HITS THE BRICK THEN IT SETS THE resetBRICK TO 1, WHICH WILL ELIMINATE THEM -------  
               if (resetBrick1 = 0) then 
                        --BRICK TOP
                       if (brick1_xr >= box_xl) and (brick1_xl <= box_xr ) and (brick1_yt >= box_yt) and (brick1_yt <= box_yb) then 
                             dir_y <= -1;
                             resetBrick1 <= 1; 
                             -- BRICK BOTTOM
                       elsif (brick1_xr >= box_xl) and (brick1_xl <= box_xr ) and (brick1_yb >= box_yt) and (brick1_yb <= box_yb) then 
                             dir_y <= 1;
                             resetBrick1 <= 1; 
                             -- BRICK RIGHT
                       elsif (brick1_yt <= box_yb) and (brick1_yb >= box_yt ) and (brick1_xr >= box_xl) and (brick1_xr <= box_xr) then 
                             dir_x <= 1;
                             resetBrick1 <= 1; 
                             -- BRICK LEFT
                       elsif (brick1_yt <= box_yb) and (brick1_yb >= box_yt ) and (brick1_xl <= box_xr) and (brick1_xl >= box_xl) then 
                             dir_x <= -1;
                             resetBrick1 <= 1;           
                       end if;  
                      
                end if;
                
               ------- THIS HERE CHECKS THE COLLISON FOR THE BRICK 2, ONCE THE BOX HITS THE BRICK THEN IT SETS THE resetBRICK TO 1, WHICH WILL ELIMINATE THEM -------  
                if (resetBrick2 = 0) then 
                 ---brick2_xl, brick2_yt, brick2_xr, brick2_yb,
                       if (brick2_xr >= box_xl) and (brick2_xl <= box_xr ) and (brick2_yt >= box_yt) and (brick2_yt <= box_yb) then 
                            dir_y <= -1;
                           resetBrick2 <= 1; 
                          
                           -- BRICK BOTTOM
                       elsif (brick2_xr >= box_xl) and (brick2_xl <= box_xr ) and (brick2_yb >= box_yt) and (brick2_yb <= box_yb) then 
                            dir_y <= 1;
                            resetBrick2 <= 1; 
                           -- BRICK RIGHT
                       elsif (brick2_yt <= box_yb) and (brick2_yb >= box_yt ) and (brick2_xr >= box_xl) and (brick2_xr <= box_xr) then 
                             dir_x <= 1;
                           resetBrick2 <= 1; 
                            -- BRICK LEFT
                       elsif (brick2_yt <= box_yb) and (brick2_yb >= box_yt ) and (brick2_xl <= box_xr) and (brick2_xl >= box_xl) then 
                            dir_x <= -1;
                           resetBrick2 <= 1;           
                       end if;
                       else
              end if; 
              
              ------- THIS HERE CHECKS THE COLLISON FOR THE BRICK 2, ONCE THE BOX HITS THE BRICK THEN IT SETS THE resetBRICK TO 1, WHICH WILL ELIMINATE THEM -------  
                                        
               if (resetBrick3 = 0) then 
                                     --BRICK TOP
                        if (brick3_xr >= box_xl) and (brick3_xl <= box_xr ) and (brick3_yt >= box_yt) and (brick3_yt <= box_yb) then 
                              dir_y <= -1;
                            resetBrick3 <= 1; 
                              -- BRICK BOTTOM
                        elsif (brick3_xr >= box_xl) and (brick3_xl <= box_xr ) and (brick3_yb >= box_yt) and (brick3_yb <= box_yb) then 
                              dir_y <= 1;
                             resetBrick3 <= 1; 
                              -- BRICK RIGHT
                        elsif (brick3_yt <= box_yb) and (brick3_yb >= box_yt ) and (brick3_xr >= box_xl) and (brick3_xr <= box_xr) then 
                              dir_x <= 1;
                            resetBrick3 <= 1; 
                              -- BRICK LEFT
                        elsif (brick3_yt <= box_yb) and (brick3_yb >= box_yt ) and (brick3_xl <= box_xr) and (brick3_xl >= box_xl) then 
                              dir_x <= -1;
                             resetBrick3 <= 1;           
                        end if;  
                        else
                 end if;
                 
                 if (resetBrick4 = 0) then 
                  ---brick4_xl, brick4_yt, brick4_xr, brick4_yb,
                        if (brick4_xr >= box_xl) and (brick4_xl <= box_xr ) and (brick4_yt >= box_yt) and (brick4_yt <= box_yb) then 
                             dir_y <= -1;
                             resetBrick4 <= 1; 
                            -- BRICK BOTTOM
                        elsif (brick4_xr >= box_xl) and (brick4_xl <= box_xr ) and (brick4_yb >= box_yt) and (brick4_yb <= box_yb) then 
                             dir_y <= 1;
                             resetBrick4 <= 1; 
                            -- BRICK RIGHT
                        elsif (brick4_yt <= box_yb) and (brick4_yb >= box_yt ) and (brick4_xr >= box_xl) and (brick4_xr <= box_xr) then 
                              dir_x <= 1;
                              resetBrick4 <= 1; 
                             -- BRICK LEFT
                        elsif (brick4_yt <= box_yb) and (brick4_yb >= box_yt ) and (brick4_xl <= box_xr) and (brick4_xl >= box_xl) then 
                             dir_x <= -1;
                              resetBrick4 <= 1;           
                        end if;
                        else
              end if; 
              
              if (resetBrick5 = 0) then 
                       --BRICK TOP
                        ---brick5_xl, brick5_yt, brick5_xr, brick5_yb
                      if (brick5_xr >= box_xl) and (brick5_xl <= box_xr ) and (brick5_yt >= box_yt) and (brick5_yt <= box_yb) then 
                            dir_y <= -1;
                           resetBrick5 <= 1; 
                            -- BRICK BOTTOM
                      elsif (brick5_xr >= box_xl) and (brick5_xl <= box_xr ) and (brick5_yb >= box_yt) and (brick5_yb <= box_yb) then 
                            dir_y <= 1;
                           resetBrick5 <= 1; 
                            -- BRICK RIGHT
                      elsif (brick5_yt <= box_yb) and (brick5_yb >= box_yt ) and (brick5_xr >= box_xl) and (brick5_xr <= box_xr) then 
                            dir_x <= 1;
                           resetBrick5 <= 1; 
                            -- BRICK LEFT
                      elsif (brick5_yt <= box_yb) and (brick5_yb >= box_yt ) and (brick5_xl <= box_xr) and (brick5_xl >= box_xl) then 
                            dir_x <= -1;
                           resetBrick5 <= 1;           
                      end if;  
                      else
              end if;
              
              if (resetBrick6 = 0) then 
                  ---brick6_xl, brick6_yt, brick6_xr, brick6_yb,
                             -- BRICK TOP
                        if (brick6_xr >= box_xl) and (brick6_xl <= box_xr ) and (brick6_yt >= box_yt) and (brick6_yt <= box_yb) then 
                             dir_y <= -1;
                             resetBrick6 <= 1; 
                            -- BRICK BOTTOM
                        elsif (brick6_xr >= box_xl) and (brick6_xl <= box_xr ) and (brick6_yb >= box_yt) and (brick6_yb <= box_yb) then 
                             dir_y <= 1;
                           resetBrick6 <= 1; 
                            -- BRICK RIGHT
                        elsif (brick6_yt <= box_yb) and (brick6_yb >= box_yt ) and (brick6_xr >= box_xl) and (brick6_xr <= box_xr) then 
                              dir_x <= 1;
                             resetBrick6 <= 1; 
                             -- BRICK LEFT
                        elsif (brick6_yt <= box_yb) and (brick6_yb >= box_yt ) and (brick6_xl <= box_xr) and (brick6_xl >= box_xl) then 
                             dir_x <= -1;
                              resetBrick6 <= 1;           
                        else
                        end if;  
              end if; 
                                      
  ------- THIS HERE CHECKS THE COLLISON FOR THE BRICK 2, ONCE THE BOX HITS THE BRICK THEN IT SETS THE resetBRICK TO 1, WHICH WILL ELIMINATE THEM -------  
                                       
             if (resetBrick7 = 0) then 
                 ---brick7_xl, brick7_yt, brick7_xr, brick7_yb,
                             --BRICK TOP
                       if (brick7_xr >= box_xl) and (brick7_xl <= box_xr ) and (brick7_yt >= box_yt) and (brick7_yt <= box_yb) then 
                             dir_y <= -1;
                            resetBrick7 <= 1; 
                             -- BRICK BOTTOM
                       elsif (brick7_xr >= box_xl) and (brick7_xl <= box_xr ) and (brick7_yb >= box_yt) and (brick7_yb <= box_yb) then 
                             dir_y <= 1;
                           resetBrick7 <= 1; 
                             -- BRICK RIGHT
                       elsif (brick7_yt <= box_yb) and (brick7_yb >= box_yt ) and (brick7_xr >= box_xl) and (brick7_xr <= box_xr) then 
                             dir_x <= 1;
                             resetBrick7 <= 1; 
                             -- BRICK LEFT
                       elsif (brick7_yt <= box_yb) and (brick7_yb >= box_yt ) and (brick7_xl <= box_xr) and (brick7_xl >= box_xl) then 
                             dir_x <= -1;
                             resetBrick7 <= 1;           
                       end if; 
                        else 
                        
                end if;
                                
 ------- THIS HERE CHECKS THE COLLISON FOR THE BRICK 2, ONCE THE BOX HITS THE BRICK THEN IT SETS THE resetBRICK TO 1, WHICH WILL ELIMINATE THEM -------  
              
               if (resetBrick8 = 0) then 
                  ---brick8_xl, brick8_yt, brick8_xr, brick8_yb,
                           --- BRICK TOP
                        if (brick8_xr >= box_xl) and (brick8_xl <= box_xr ) and (brick8_yt >= box_yt) and (brick8_yt <= box_yb) then 
                             dir_y <= -1;
                             resetBrick8 <= 1; 
                            -- BRICK BOTTOM
                        elsif (brick8_xr >= box_xl) and (brick8_xl <= box_xr ) and (brick8_yb >= box_yt) and (brick8_yb <= box_yb) then 
                             dir_y <= 1;
                             resetBrick8 <= 1; 
                            -- BRICK RIGHT
                        elsif (brick8_yt <= box_yb) and (brick8_yb >= box_yt ) and (brick8_xr >= box_xl) and (brick8_xr <= box_xr) then 
                              dir_x <= 1;
                           resetBrick8 <= 1; 
                             -- BRICK LEFT
                        elsif (brick8_yt <= box_yb) and (brick8_yb >= box_yt ) and (brick8_xl <= box_xr) and (brick8_xl >= box_xl) then 
                             dir_x <= -1;
                             resetBrick8 <= 1;           
                        end if;
                        else 
                        end if;
               
        end if;   
	end process;	
	
	
    -- compute the next x,y position of box 
    process ( update_pos, x, y, xS,yS )
    begin
        if rising_edge(update_pos) then 
			next_x <= x + dir_x;
			next_y <= y + dir_y;
           next_xS <= xS + dir_xS;
           next_yS <= yS + dir_yS;
       end if;
       end process;
    
    -- process to generate next colors           
    process (pixel_x, pixel_y)
    begin
        
           if (unsigned(pixel_x) > box_xl) and (unsigned(pixel_x) < box_xr) and
                (unsigned(pixel_y) > box_yt) and (unsigned(pixel_y) < box_yb) then
                  -- foreground box color cyan
                 red_next <= "0000";
                 green_next <= "1111";
                 blue_next <= "1111"; 
           elsif (unsigned(pixel_x) > slidebar_xl) and (unsigned(pixel_x) < slidebar_xr) and
                 (unsigned(pixel_y) > slidebar_yt) and (unsigned(pixel_y) < slidebar_yb) then
                                -- foreground color white 
                 red_next <= "1111";
                 green_next <= "1111";
                 blue_next <= "1111";
                ------ COLOR DARW FOR BRICK 1 --------- 
          elsif (unsigned(pixel_x) > brick1_xl) and (unsigned(pixel_x) < brick1_xr) and
                (unsigned(pixel_y) > brick1_yt) and (unsigned(pixel_y) < brick1_yb) then
            -- foreground color magenta -
            --- if reset is 0 then the color magenta will show or it will be black
                if ((resetBrick1 = 0) or (resetBrick1 = 1)) then 
                    red_next <= "1111";
                    green_next <= "0000";
                    blue_next <= "1111";   
                else 
                    red_next <= "0000";
                    green_next <= "0000";
                    blue_next <= "0000";   
                end if;
            ------ COLOR DARW FOR BRICK 2 --------- 
           elsif (unsigned(pixel_x) > brick2_xl) and (unsigned(pixel_x) < brick2_xr) and
                 (unsigned(pixel_y) > brick2_yt) and (unsigned(pixel_y) < brick2_yb) then
            -- foreground color magenta -
            --- if reset is 0 then the color magenta will show or it will be black
                if (resetBrick2 = 0) then 
                    red_next <= "1111";
                    green_next <= "0000";
                    blue_next <= "1111";   
                else 
                    red_next <= "0000";
                    green_next <= "0000";
                    blue_next <= "0000";   
                end if;     
                
                 ------ COLOR DARW FOR BRICK 3 ---------
              elsif (unsigned(pixel_x) > brick3_xl) and (unsigned(pixel_x) < brick3_xr) and
                    (unsigned(pixel_y) > brick3_yt) and (unsigned(pixel_y) < brick3_yb) then
              -- foreground color magenta -
              --- if reset is 0 then the color magenta will show or it will be black
                  if (resetBrick3 = 0) then 
                      red_next <= "1111";
                      green_next <= "0000";
                      blue_next <= "1111";   
                  else 
                      red_next <= "0000";
                      green_next <= "0000";
                      blue_next <= "0000";   
                  end if;
               
             ------ COLOR DARW FOR BRICK 4 ---------
             elsif (unsigned(pixel_x) > brick4_xl) and (unsigned(pixel_x) < brick4_xr) and
                   (unsigned(pixel_y) > brick4_yt) and (unsigned(pixel_y) < brick4_yb) then
             -- foreground color magenta -
             --- if reset is 0 then the color magenta will show or it will be black
                  if (resetBrick4 = 0) then 
                      red_next <= "1111";
                      green_next <= "0000";
                      blue_next <= "1111";   
                  else 
                      red_next <= "0000";
                      green_next <= "0000";
                      blue_next <= "0000";   
                  end if; 
              
                 ------ COLOR DARW FOR BRICK 5 --------- 
             elsif (unsigned(pixel_x) > brick5_xl) and (unsigned(pixel_x) < brick5_xr) and
                   (unsigned(pixel_y) > brick5_yt) and (unsigned(pixel_y) < brick5_yb) then
               -- foreground color magenta -
               --- if reset is 0 then the color magenta will show or it will be black
                   if (resetBrick5 = 0) then 
                       red_next <= "1111";
                       green_next <= "0000";
                       blue_next <= "1111";   
                   else 
                       red_next <= "0000";
                       green_next <= "0000";
                       blue_next <= "0000";   
                   end if; 
                  
               ------ COLOR DARW FOR BRICK 6 --------- 
              elsif (unsigned(pixel_x) > brick6_xl) and (unsigned(pixel_x) < brick6_xr) and
                    (unsigned(pixel_y) > brick6_yt) and (unsigned(pixel_y) < brick6_yb) then
               -- foreground color magenta -
               --- if reset is 0 then the color magenta will show or it will be black
                   if (resetBrick6 = 0) then 
                       red_next <= "1111";
                       green_next <= "0000";
                       blue_next <= "1111";   
                   else 
                       red_next <= "0000";
                       green_next <= "0000";
                       blue_next <= "0000";   
                   end if;  
                  
                    ------ COLOR DARW FOR BRICK 7 ---------
                 elsif (unsigned(pixel_x) > brick7_xl) and (unsigned(pixel_x) < brick7_xr) and
                       (unsigned(pixel_y) > brick7_yt) and (unsigned(pixel_y) < brick7_yb) then
                 -- foreground color magenta -
                 --- if reset is 0 then the color magenta will show or it will be black
                     if (resetBrick7 = 0) then 
                         red_next <= "1111";
                         green_next <= "0000";
                         blue_next <= "1111";   
                     else 
                         red_next <= "0000";
                         green_next <= "0000";
                         blue_next <= "0000";   
                     end if;
                     
                ------ COLOR DARW FOR BRICK 8 ---------
                elsif (unsigned(pixel_x) > brick8_xl) and (unsigned(pixel_x) < brick8_xr) and
                      (unsigned(pixel_y) > brick8_yt) and (unsigned(pixel_y) < brick8_yb) then
                -- foreground color magenta -
                -- if reset is 0 then the color magenta will show or it will be black
                     if (resetBrick8 = 0) then 
                         red_next <= "1111";
                         green_next <= "0000";
                         blue_next <= "1111";   
                     else 
                         red_next <= "0000";
                         green_next <= "0000";
                         blue_next <= "0000";   
                     end if; 

           else    
               -- background color black
               red_next <= "0000";
               green_next <= "0000";
               blue_next <= "0000";
           end if;  
         
            
            
    end process;

   -- generate r,g,b registers
   process ( video_on, pixel_tick, red_next, green_next, blue_next)
   begin
      if rising_edge(pixel_tick) then
          if (video_on = '1') then
            red_reg <= red_next;
            green_reg <= green_next;
            blue_reg <= blue_next;   
          else
            red_reg <= "0000";
            green_reg <= "0000";
            blue_reg <= "0000";                    
          end if;
      end if;
   end process;
   
   red <= STD_LOGIC_VECTOR(red_reg);
   green <= STD_LOGIC_VECTOR(green_reg); 
   blue <= STD_LOGIC_VECTOR(blue_reg);
     
end bouncing_box;