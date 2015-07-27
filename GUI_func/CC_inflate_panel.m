function CC_inflate_panel(varargin)

H=varargin{1};
handles=guidata(H);

subplot_nr=varargin{3};

axes_handle=handles.figure_handles(subplot_nr);
cur_pos=get(axes_handle,'position');
fullsize_pos=[0.230 0.1100 0.550 0.8150];

xPos=.82;
yPos=.12;
window_size=.2;
side_pos=[xPos yPos window_size window_size ; xPos yPos+window_size*1.5 window_size window_size ; xPos yPos+window_size*3 window_size window_size];
nSubplots=length(handles.figure_handles);

if all(eq(cur_pos,fullsize_pos))
    %%% Deflate: restore defaults
    for iSubplot=1:nSubplots
        axes_handle=handles.figure_handles(iSubplot);
        default_pos=handles.axis_positions(iSubplot,:);
        set(axes_handle,'position',default_pos);
        set(handles.axis_inflate_buttons(iSubplot),'BackgroundColor','r')
    end
    set(handles.mask_handles(1),'position',handles.axis_positions(1,:));
    set(handles.layer2_handles(1),'position',handles.axis_positions(1,:));
    set(handles.mask_handles(2),'position',handles.axis_positions(2,:));
    handles.window_priority=0;
else
    %%% Inflate
    count=1;
    for iSubplot=1:nSubplots
        axes_handle=handles.figure_handles(iSubplot);
        if iSubplot==subplot_nr
            set(axes_handle,'position',fullsize_pos);
            set(handles.axis_inflate_buttons(iSubplot),'BackgroundColor','b')
            switch iSubplot
                case 1
                    set(handles.mask_handles(1),'position',fullsize_pos);
                    set(handles.layer2_handles(1),'position',fullsize_pos);
                case 2
                    set(handles.mask_handles(2),'position',fullsize_pos);
            end
        else
            set(axes_handle,'position',side_pos(4-count,:));
            count=count+1;
            set(handles.axis_inflate_buttons(iSubplot),'BackgroundColor','r')
            switch iSubplot
                case 1
                    set(handles.mask_handles(1),'position',side_pos(3,:));
                    set(handles.layer2_handles(1),'position',side_pos(3,:));                    
                case 2
                    if subplot_nr==1
                        set(handles.mask_handles(2),'position',side_pos(3,:));                        
                    else
                        set(handles.mask_handles(2),'position',side_pos(2,:));
                    end
            end
        end
    end    
    handles.window_priority=subplot_nr;
end

guidata(H,handles);