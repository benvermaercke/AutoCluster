function CC_sync_axes(varargin)
H=varargin{1};
handles=guidata(H);
%axes_number=varargin{3};
axes_number=handles.window_priority;

if axes_number==1
    set(handles.layer2_handles(1),'Xlim',get(handles.mask_handles(axes_number),'Xlim'),'Ylim',get(handles.mask_handles(axes_number),'Ylim'))
end

set(handles.figure_handles(axes_number),'Xlim',get(handles.mask_handles(axes_number),'Xlim'))
set(handles.figure_handles(axes_number),'Ylim',get(handles.mask_handles(axes_number),'Ylim'))