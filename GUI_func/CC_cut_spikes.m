function CC_cut_spikes(varargin)

H=varargin{1};
handles=guidata(H);
operation=varargin{3};

selected_cluster=handles.selected_cluster;
cluster_vector=handles.cluster_vector;

ROIx=handles.ROIx;
ROIy=handles.ROIy;
ClusterAllocation=handles.ClusterAllocation;
sel=ClusterAllocation==selected_cluster;

if ~isempty(ROIx)
    switch handles.window_priority
        case 1
            P1=handles.spikeMatrix(:,3+handles.var1);
            P2=handles.spikeMatrix(:,3+handles.var2);
            ellipse=handles.ellipse;
            
            %% Make selection based on ROI
            switch get(handles.use_ellipse_bt,'value') % use row polygon or fitted ellipse
                case 0
                    IN=inpolygon(P1,P2,ROIx,ROIy);
                case 1
                    IN=in_ellipse(P1,P2,ellipse.a,ellipse.b,ellipse.X0_in,ellipse.Y0_in,ellipse.phi);
            end
                       
            switch operation % subtract or add operation
                case 'cut' % Cut spikes that fall outside of ROI (like SpikeSort did)
                    ClusterAllocation(sel&IN==0)=0;
                case 'add' % Assign all spikes within ROI to selected cluster
                    ClusterAllocation(IN==1)=selected_cluster;
                case 'move'                    
                    new_cluster_nr=CC_find_next_cluster_number(cluster_vector);
                    temp=ClusterAllocation(sel);
                    temp(IN(sel)==1)=new_cluster_nr;
                    ClusterAllocation(sel)=temp;   
                    %ClusterAllocation(IN==1)=new_cluster_nr;
                    
                    %%% Update cluster properties
                    cluster_vector=sort([cluster_vector ; new_cluster_nr]);
                    handles.cluster_vector=cluster_vector;   
                    handles=CC_calc_properties(handles,new_cluster_nr);
            end
            
            set(handles.cut_spikes_bt,'enable','off')
            set(handles.add_spikes_bt,'enable','off')
            set(handles.move_spikes_bt,'enable','off')
            handles.ellipse=[];
        case 2
            sel=ClusterAllocation==selected_cluster;
            waveforms=squeeze(handles.spikeData(:,:,sel));
            
            nBoxes=floor(size(ROIx,1)/2);
            for iBox=1:nBoxes
                x=unique(ROIx((iBox-1)*2+1:(iBox-1)*2+2));
                y=sort(ROIy((iBox-1)*2+1:(iBox-1)*2+2))';
                data=waveforms(x(1):x(end),:);
                IN=all(between(data,y),1);
            end
            
            switch operation % subtract or add operation
                case 'cut' % Cut spikes that fall outside of ROI (like SpikeSort did)
                    temp=ClusterAllocation(sel);
                    temp(IN==0)=0;
                    ClusterAllocation(sel)=temp;
                case 'move'
                    new_cluster_nr=CC_find_next_cluster_number(cluster_vector);
                    temp=ClusterAllocation(sel);
                    temp(IN==1)=new_cluster_nr;
                    ClusterAllocation(sel)=temp;     
                    
                    %%% Update cluster properties
                    cluster_vector=sort([cluster_vector ; new_cluster_nr]);
                    handles.cluster_vector=cluster_vector;   
                    handles=CC_calc_properties(handles,new_cluster_nr);
            end
            set(handles.cut_spikes_bt,'enable','off')
            set(handles.move_spikes_bt,'enable','off')
            set(H,'ButtonDownFcn',[]);
    end
    handles.ClusterAllocation=ClusterAllocation;
    handles.ROIx=[];
    handles.ROIy=[];
                 
    %%% Make new entry in history matrix
    handles.ClusterAllocation_history=[handles.ClusterAllocation_history(:,1:handles.history_index) ClusterAllocation];
    handles.history_index=handles.history_index+1;
    guidata(H,handles)
    CC_update_gui(handles)
end