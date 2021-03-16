import pandas as pd
import numpy as np
import os
import sys

def subtract_units(row, group):
    higher_priority = group[group['source_id'] < row['source_id']]
    higher_priority_units = higher_priority['units_net'].sum()
    row['units_net'] = row['units_net'] - higher_priority_units
    if row['units_net'] < 0:
        row['units_net'] = 0
    return row

def resolve_project(group):
    if group.shape[0] > 1:
        group = group.sort_values('source_id')
        group = group.reset_index()
        for index, row in group.iterrows():
            group.iloc[index] = subtract_units(row, group)
    return group

def resolve_all_projects(df):
    # Hierarchy for unit subtraction
    hierarchy = {'DOB': 1,
            'HPD Projected Closings':2,
            'HPD RFPs':3,
            'EDC Projected Projects':4,
            'DCP Application':5,
            'Empire State Development Projected Projects':6,
            'Neighborhood Study Rezoning Commitments':7,
            'Neighborhood Study Projected Development Sites':8,
            'DCP Planner-Added Projects':9}

    df['source_id'] = df['source'].map(hierarchy)

    # Subtract units within cluster based on hierarchy
    print("Subtracting units within projcts based on source hierarchy...")
    resolved = df.groupby(['project_id'], as_index=False).apply(resolve_project)
    try:
        resolved = resolved.drop(columns=['level_0'])
    except:
        pass
    try:
        resolved = resolved.drop(columns=['index'])
    except:
        pass
    print("Output of unit subtraction: \n", 
        resolved[['source', 'units_gross', 'units_net', 'project_id']].head(10))

    return resolved

if __name__ == "__main__":

    # Read table from standard input
    df = pd.read_csv(sys.stdin)
    df['units_gross'] = df['units_gross'].astype(float)
    df['units_net'] = df['units_gross'].astype(float)

    # Resolve table and export to standard output
    resolved = resolve_all_projects(df)
    cols = ['record_id','source', 'units_gross', 'units_net', 'project_id']
    resolved[cols].to_csv(sys.stdout, index=False)