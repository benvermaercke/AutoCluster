function CC_select_poly(varargin)

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
    ROIx=cat(1,handles.ROIx,x);
    ROIy=cat(1,handles.ROIy,y);
    
    %%% Allow refining of the polygon
    phi=cart2pol(ROIx-mean(ROIx),ROIy-mean(ROIy));    
    [phi order]=sort(phi,'ascend');
    ROIx=ROIx(order);ROIy=ROIy(order);
    
    handles.ROIx=ROIx;
    handles.ROIy=ROIy;
    
    %%% Show dots that were marked
    ROIx=[ROIx ; ROIx(1)];ROIy=[ROIy ; ROIy(1)];
    set(handles.ROI_polygon,'Xdata',ROIx,'Ydata',ROIy,'color',handles.cheetahColors(handles.nColors+1-handles.selected_cluster,:))
elseif strcmpi(clickType,'alt')
    ROIx=handles.ROIx;
    ROIy=handles.ROIy;
    set(H,'ButtonDownFcn',[]);
    
    min_N_points=5;
    if length(ROIx)>min_N_points    
        ROIx=[ROIx ; ROIx(1)];ROIy=[ROIy ; ROIy(1)];
        set(handles.ROI_polygon,'Xdata',ROIx,'Ydata',ROIy,'color',handles.cheetahColors(handles.nColors+1-handles.selected_cluster,:))
        
        if get(handles.use_ellipse_bt,'value')==1
            nPoints=100;
            ellipse=fit_ellipse(ROIx,ROIy);
            delete(handles.ROI_ellipse)
            handles.ROI_ellipse=plotEllipse(ellipse.a,ellipse.b,-ellipse.phi,ellipse.X0_in,ellipse.Y0_in,min([handles.cheetahColors(handles.nColors+1-handles.selected_cluster,:)+.2 ; 1 1 1]),nPoints);
            handles.ellipse=ellipse;
        end
    else
        %disp('ROI definition interrupted')
        set(handles.ROI_polygon,'Xdata',handles.xRange(1),'Ydata',handles.yRange(1),'color','k')
        set(handles.ROI_ellipse,'Xdata',handles.xRange(1),'Ydata',handles.yRange(1),'color','k')
    end
end


guidata(H,handles);