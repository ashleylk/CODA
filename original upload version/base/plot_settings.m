function plot_settings(ll)
if nargin==0;ll=0;end
    axis equal;axis on;box on;
    daspect([1 1 1])
    camva(9.72)
    set(gcf,'color','w');
    set(gca,'xtick',[],'ytick',[],'ztick',[])
    xlabel('');zlabel('');ylabel('');

    el=23;
    az=44;
    view(az,el)
if ll
    delete(findall(gcf,'Type','light'))
    set(gca,'CameraViewAngleMode','Manual')
    camlight
    lighting gouraud
    lightangle(az,el)
end
end