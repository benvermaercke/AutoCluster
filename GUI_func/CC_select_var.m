function CC_select_var(varargin)

H=varargin{1};
handles=guidata(H);
var=varargin{3};
value=get(H,'value');
eval(['handles.var' num2str(var) '=value;'])

%%% Rescale axis
P=handles.spikeMatrix(:,3+value);
maxval=max(abs(P));Range=[-maxval maxval]*1.5;
if var==1
    set(handles.figure_handles(1),'Xlim',Range)
    set(get(handles.figure_handles(1),'XLabel'),'string',handles.property_names{value})
    set(handles.layer2_handles(1),'Xlim',Range)
    set(handles.mask_handles(1),'Xlim',Range)
else
    set(handles.figure_handles(1),'Ylim',Range)
    set(get(handles.figure_handles(1),'YLabel'),'string',handles.property_names{value})
    set(handles.layer2_handles(1),'Ylim',Range)
    set(handles.mask_handles(1),'Ylim',Range)
end

guidata(H,handles)

CC_update_gui(handles)
