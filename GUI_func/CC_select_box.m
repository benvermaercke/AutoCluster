function CC_select_box(varargin)

H=varargin{1};
handles=guidata(H);

switch get(H,'Type')
    case 'axes'
        CurrentPoint=get(H,'CurrentPoint');
    case 'line'
        get(H)
end

clickType=get(handles.figure1,'SelectionType');

if strcmpi(clickType,'normal')
    x=CurrentPoint(1,1);
    y=CurrentPoint(1,2);
    ROIx=cat(1,handles.ROIx,round(x));
    ROIy=cat(1,handles.ROIy,y);        
    
    handles.ROIx=ROIx;
    handles.ROIy=ROIy;
    
    guidata(H,handles);
    
    %%% Show dots that were marked     
    set(handles.ROI_box_points,'Xdata',ROIx,'Ydata',ROIy,'color',handles.cheetahColors(handles.nColors+1-handles.selected_cluster,:))
    
    if length(ROIx)==2
        updateRect(handles.ROI_rect,[ROIx(1) ROIy(1) ROIx(2) ROIy(2)],handles.cheetahColors(handles.nColors+1-handles.selected_cluster,:))
    end
    
    %     if mod(size(ROIx,1),2)==0
    %         CC_cut_spikes(H,[],'cut')
    %     end
elseif strcmpi(clickType,'alt')
    set(H,'ButtonDownFcn',[]);
    set(handles.ROI_box_points,'Xdata',handles.xRange(1),'Ydata',handles.yRange(1),'color','k')
    set(handles.ROI_box,'Xdata',handles.xRange(1),'Ydata',handles.yRange(1),'color','k')

end

%guidata(H,handles);