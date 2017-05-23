
%+----------------------------------------------------------+
%|                                                          | 
%| Interpolate1():Linear Interpolation routine for STD data | 
%| in decreasing order.                                     |
%|                                                          |
%| Inputs..........: InTemperature[N][M]  input temperature |
%|                   InPressure[N][M]     input pressure    |
%|                   StandardPressure[L]  standard pressure |
%|                                                          |
%| Outputs.........: StandardTemperature[L][M] standard temp|
%|                                                          |
%| Call Format.....:                                        | 
%|                                                          |
%+----------------------------------------------------------+

function StandardTemperature=InterpolateLow2(InTemperature, InPressure, StandardPressure)

[IROWS,ICOLS]=size(InTemperature); 
[SROWS,SCOLS]=size(StandardPressure);
SCOLS=ICOLS;

for c=1:ICOLS,
   ROWS=IROWS;
   for r=1:SROWS, StandardTemperature(r,c)=NaN; end

   while(InTemperature(ROWS,c)==NaN),
      if (ROWS<=1) break; end 
      ROWS=ROWS-1; 
   end

   if (ROWS>=2)
      for r=1:SROWS,
         P=StandardPressure(r);
         StandardTemperature(r,c)=NaN;

         for Index=1:ROWS-1, 
            P1=InPressure(Index+0,c);
            P2=InPressure(Index+1,c);

            if ((P<=P1) & (P>=P2))
               T1=InTemperature(Index+0, c);
               T2=InTemperature(Index+1, c);
               StandardTemperature(r,c)=(T2-T1)/(P2-P1)*(P-P1) + T1;
            end 
         end
      end
   end

end 

