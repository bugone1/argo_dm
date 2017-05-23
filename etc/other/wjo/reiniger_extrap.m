function StandardTemperature=Reiniger(InTemperature, InPressure, StandardPressure,tol)
%| Reiniger():Oceanographic Interpolation of Temperature onto Standard Pressure Levels                                                           |
%|           :for Argo, we are interpolating onto Standard Temperature Levels so pressure becomes temperature.                                   | 
%|           :Temperature may be non-monotonic in profile data so we take the deepest occurrance of the Standard Temperature in the profile.     |
%| Inputs..........: InTemperature[N][M]  input profile temperature (becomes salinity or pressure)                                               |
%|                   InPressure[N][M]     input profile pressure    (becomes potential temperature going from shallowest to deepest)             |
%|                   StandardPressure[L]  standard pressure         (becomes Standard Temperature)                                               |
%|                   tol                  interpolation error tolerance                                                                          |
%|                                                                                                                                               |
%| Outputs.........: StandardTemperature[L][M] (becomes standard salinity or pressure)                                                                                    |
%|                                                                                                                                               |
%| REINIGER R.F. and ROSS C.K., 1968. A method of interpolation with application to oceanographic data. Deep-Sea Research, Vol 15, pp 185-193.   |
%+-----------------------------------------------------------------------------------------------------------------------------------------------+

% CODE SECTION IN interpolate_float_values.m USED TO CALL reiniger_extrap.m WITH
% TOLERANCE OF .01 FOR SALINITY AND 15 DBAR FOR PRESSURE.

% akima has trouble with less than 3 numbers. Reiniger can use 2 but leave
% this in.

% if( length( find( isnan( ln_ptmp ) == 0 ) ) > 3 )
%    if( length( find( isnan( ln_sal ) == 0 ) ) > 3 )
%       pa_interp_sal = reiniger_extrap( ln_sal, ln_ptmp, pa_levels(1:pn_max_number_of_levels),.01 ) ;
%       la_compare_sal = interpolate1( ln_sal,  ln_ptmp, pa_levels(1:pn_max_number_of_levels) ) ;
%    end
%    if( length( find( isnan( ln_pres ) == 0 ) ) > 3 )
%       pa_interp_pres = reiniger_extrap( ln_pres, ln_ptmp, pa_levels(1:pn_max_number_of_levels),15 ) ;
%       la_compare_pres = interpolate1( ln_pres, ln_ptmp, pa_levels(1:pn_max_number_of_levels) ) ;
%    end
% end

[IROWS,ICOLS]=size(InTemperature); 
[SROWS,SCOLS]=size(StandardPressure);
SCOLS=ICOLS;

for c=1:ICOLS,
   ROWS=IROWS;
   StandardTemperature(1:SROWS,c)=NaN;
   while(isnan(InTemperature(ROWS,c))),
      if (ROWS<=1) break; end 
      ROWS=ROWS-1; 
   end
   
   if (ROWS>=4)
      for r=1:SROWS,
         P=StandardPressure(r);
         StandardTemperature(r,c)=NaN;

         for Index=1:ROWS-1, 
            P1=InPressure(Index+0,c);
            P2=InPressure(Index+1,c);
            if P2==P1;continue;end

            if (((P<=P1) & (P>=P2)) | ((P>=P1) & (P<=P2)) | Index==ROWS-1) %find each case of matching the StandardPressure. Keep the deepest. Try to extrapolate if data has run out.
               T1=InTemperature(Index+0, c);
               T2=InTemperature(Index+1, c);
               Ph12=(T2-T1)/(P2-P1)*(P-P1) + T1; %linear interpolation or extrapolation
               if(Index>1 & Index<=ROWS-2)
                   P3=InPressure(Index+2, c);
                   T3=InTemperature(Index+2, c);
                   P0=InPressure(Index-1, c);
                   T0=InTemperature(Index-1, c);
                   Ph01=(T1-T0)/(P1-P0)*(P-P1) + T1;
                   Ph23=(T3-T2)/(P3-P2)*(P-P2) + T2;
                   % Reference estimate
                   DENOM=(Ph12-Ph23)^2+(Ph01-Ph12)^2;
                   if DENOM>0;
                    PhR=.5*(Ph12+((Ph12-Ph23)^2*Ph01+(Ph01-Ph12)^2*Ph23)/(DENOM));
                   else
                    PhR=Ph12;
                   end
                   % Lagrangian interpolations
                   REINIGER2=T1*(P-P2)*(P-P3)/((P1-P2)*(P1-P3))+T2*(P-P1)*(P-P3)/((P2-P1)*(P2-P3))+T3*(P-P1)*(P-P2)/((P3-P1)*(P3-P2));
                   REINIGER1=T0*(P-P1)*(P-P2)/((P0-P1)*(P0-P2))+T1*(P-P0)*(P-P2)/((P1-P0)*(P1-P2))+T2*(P-P0)*(P-P1)/((P2-P0)*(P2-P1));
                   DENOM=(abs(PhR-REINIGER1)+abs(PhR-REINIGER2));
                   if DENOM>0
                       Reiniger=(abs(PhR-REINIGER1)*REINIGER2+abs(PhR-REINIGER2)*REINIGER1)/DENOM;
                   else
                       Reiniger=PhR;
                   end
                   %estimated error
                   if sqrt(abs((Reiniger-REINIGER1)*(Reiniger-REINIGER2)))/3 < tol;
                       StandardTemperature(r,c)=Reiniger;
                   else
                       StandardTemperature(r,c)=nan;
                   end
               elseif (Index==1)
                   P3=InPressure(Index+2, c);
                   T3=InTemperature(Index+2, c);
                   P4=InPressure(Index+3, c);
                   T4=InTemperature(Index+3, c);
                   Ph34=(T3-T4)/(P3-P4)*(P-P3) + T3;
                   Ph23=(T3-T2)/(P3-P2)*(P-P2) + T2;
                   Ph13=(T3-T1)/(P3-P1)*(P-P1) + T1;
                   % Reference estimate
                   DENOM=(Ph12-Ph23)^2+(Ph12-Ph13)^2;
                   if DENOM>0;
                   PhR=.5*(Ph12+((Ph12-Ph23)^2*Ph34+(Ph12-Ph13)^2*Ph23)/(DENOM));
                   else
                    PhR=Ph12;
                   end
                   % Lagrangian interpolations
                   REINIGER2=T1*(P-P2)*(P-P4)/((P1-P2)*(P1-P4))+T2*(P-P1)*(P-P4)/((P2-P1)*(P2-P4))+T4*(P-P1)*(P-P2)/((P4-P1)*(P4-P2));
                   REINIGER1=T3*(P-P1)*(P-P2)/((P3-P1)*(P3-P2))+T1*(P-P2)*(P-P3)/((P1-P2)*(P1-P3))+T2*(P-P3)*(P-P1)/((P2-P3)*(P2-P1));
                   DENOM=abs(PhR-REINIGER1)+abs(PhR-REINIGER2);
                   if DENOM>0
                       Reiniger=(abs(PhR-REINIGER1)*REINIGER2+abs(PhR-REINIGER2)*REINIGER1)/DENOM;
                   else
                       Reiniger=PhR;
                   end
                   %estimated error
                   if sqrt(abs((Reiniger-REINIGER1)*(Reiniger-REINIGER2)))/3 < tol;
                       StandardTemperature(r,c)=Reiniger;
                   else
                       StandardTemperature(r,c)=nan;
                   end
               elseif (Index==(ROWS-1)) %mirror image of the above block
                   if ~(((P<=P1) & (P>=P2)) | ((P>=P1) & (P<=P2))) % P2 is the last data point. Allow extrapolation to pick up the last level?
                       if ~isnan(StandardTemperature(r,c)) | r<5 | abs((P-P2)/(StandardPressure(r)-StandardPressure(r-1,c)))>.1 | isnan(StandardTemperature(r-1,c)) 
                           %allow extrapolation over 10% of the interval between the last two levels
                           break
                       else
                           T4=StandardTemperature(r-1,c);P4=StandardPressure(r-1)
                           Ph42=T2+(T4-T2)/(P4-P2)*(P-P2)
                           Ph41=T1+(T4-T1)/(P4-P1)*(P-P1)
                           if abs(Ph42-Ph41)<tol
                               StandardTemperature(r,c)=(Ph42+Ph41)/2; %average the linear extrapolations from the last good standard value
                               break
                           else
                               break
                           end
                       end
                   end
                           
                   p2=P1;P1=P2;P2=p2;
                   t2=T1;T1=T2;T2=t2;
                   P3=InPressure(Index-1, c);
                   T3=InTemperature(Index-1, c);
                   P4=InPressure(Index-2, c);
                   T4=InTemperature(Index-2, c);
                   Ph34=(T3-T4)/(P3-P4)*(P-P3) + T3;
                   Ph23=(T3-T2)/(P3-P2)*(P-P2) + T2;
                   Ph13=(T3-T1)/(P3-P1)*(P-P1) + T1;
                   % Reference estimate
                   DENOM=(Ph12-Ph23)^2+(Ph12-Ph13)^2;
                   if DENOM>0;
                   PhR=.5*(Ph12+((Ph12-Ph23)^2*Ph34+(Ph12-Ph13)^2*Ph23)/(DENOM));
                   else
                    PhR=Ph12;
                   end
                   % Lagrangian interpolations
                   REINIGER2=T1*(P-P2)*(P-P4)/((P1-P2)*(P1-P4))+T2*(P-P1)*(P-P4)/((P2-P1)*(P2-P4))+T4*(P-P1)*(P-P2)/((P4-P1)*(P4-P2));
                   REINIGER1=T3*(P-P1)*(P-P2)/((P3-P1)*(P3-P2))+T1*(P-P2)*(P-P3)/((P1-P2)*(P1-P3))+T2*(P-P3)*(P-P1)/((P2-P3)*(P2-P1));
                     DENOM=abs(PhR-REINIGER1)+abs(PhR-REINIGER2);
                   if DENOM>0
                       Reiniger=(abs(PhR-REINIGER1)*REINIGER2+abs(PhR-REINIGER2)*REINIGER1)/DENOM;
                   else
                       Reiniger=PhR;
                   end
                   %estimated error
                   if sqrt(abs((Reiniger-REINIGER1)*(Reiniger-REINIGER2)))/3 < tol;
                       StandardTemperature(r,c)=Reiniger;
                   else
                       StandardTemperature(r,c)=nan; %remove if the error is large
                   end
                end % index
              end % P is bracketed
         end %for index
      end %for ROWs
   end % ROW's >2
end % for columns