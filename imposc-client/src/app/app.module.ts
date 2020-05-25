import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms'; // <-- NgModel lives here

import { AppComponent } from './app.component';
import { ChartsComponent } from './charts/charts.component';
import { ChartDetailComponent } from './chart-detail/chart-detail.component';
import { MessagesComponent } from './messages/messages.component';
import { AppRoutingModule } from './app-routing.module';
import { DashboardComponent } from './dashboard/dashboard.component';

@NgModule({
  declarations: [
    AppComponent,
    ChartsComponent,
    ChartDetailComponent,
    MessagesComponent,
    DashboardComponent
  ],
  imports: [
  BrowserModule,
  FormsModule,
  AppRoutingModule
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
