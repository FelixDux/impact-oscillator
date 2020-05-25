import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { ChartsComponent } from './charts/charts.component';
import { ChartDetailComponent }  from './chart-detail/chart-detail.component';
import { DashboardComponent }   from './dashboard/dashboard.component';

const routes: Routes = [
  { path: '', redirectTo: '/dashboard', pathMatch: 'full' },
  { path: 'dashboard', component: DashboardComponent },
  { path: 'detail/:name', component: ChartDetailComponent },
  { path: 'charts', component: ChartsComponent }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
