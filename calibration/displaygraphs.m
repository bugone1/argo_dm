FigNo=4;
while ~isempty(FigNo) && FigNo<10 && FigNo>0 %examine figures to come to an opinion about the conductivity cell calibration
    flnm=[lo_system_configuration.FLOAT_PLOTS_DIRECTORY floatNum '_' num2str(FigNo,'%1d') '.png'];
    ['New Plot: ' flnm ]
    if ~ispc
    system(['eog ' flnm ]);
    else
        system(flnm);
    end
    FigNo=input('Which Figure; 1-9? (other: calibrate, -1: next float)');
end