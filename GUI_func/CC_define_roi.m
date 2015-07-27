function CC_define_roi(varargin)
H=varargin{1};
handles=guidata(H);

%% Define ROI for selected cluster
handles.ROIx=[];
handles.ROIy=[];
guidata(H,handles);
switch handles.window_priority
    case 1
        set(handles.ROI_polygon,'Xdata',handles.xRange(1),'Ydata',handles.yRange(1),'color','k')
        set(handles.ROI_ellipse,'Xdata',handles.xRange(1),'Ydata',handles.yRange(1),'color','k')
        set(handles.mask_handles(1),'ButtonDownFcn',@CC_select_poly)
        set(handles.cut_spikes_bt,'enable','on')
        set(handles.add_spikes_bt,'enable','on')
        set(handles.move_spikes_bt,'enable','on')
    case 2
        set(handles.ROI_box_points,'Xdata',handles.xRange(1),'Ydata',handles.yRange(1),'color','k')
        set(handles.ROI_box,'Xdata',handles.xRange(1),'Ydata',handles.yRange(1),'color','k')
        set(handles.mask_handles(2),'ButtonDownFcn',@CC_select_box)        
        set(handles.cut_spikes_bt,'enable','on')
        set(handles.move_spikes_bt,'enable','on')
end

