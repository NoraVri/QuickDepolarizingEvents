function [intersections] = intersecting_vectors_in_cells(A,B)
intersections = cell(1,length(A));
    for i = 1:length(A)
        vA = A{i};
        vB = B{i};
        intersections{i} = intersect(vA,vB);
    end
end

