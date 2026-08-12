import React from 'react';
import Sectiontitle from '../section-title'
import team1 from '../../images/team/2.jpg'
import team2 from '../../images/team/4.jpg'
import './style.css'


const Team = () => {
    return(
        <div className="team-area">
            <Sectiontitle section={'Our team'}/>
            <div className="container">
                <div className="row">
                    <div className="col-lg-3">
                        <div className="team-img">
                            <img src={team1} alt=""/>
                        </div>
                        <div className="team-text">
                            <h2>Rashed</h2>
                            <p>react developer</p>
                        </div>
                    </div>
                    <div className="col-lg-3">
                        <div className="team-img">
                            <img src={team2} alt=""/>
                        </div>
                        <div className="team-text">
                            <h2>naim</h2>
                            <p>figma developer</p>
                            
                        </div>
                    </div>
                    <div className="col-lg-3">
                        <div className="team-img">
                            <img src={team1} alt=""/>
                        </div>
                        <div className="team-text">
                            <h2>shahin</h2>
                            <p>react developer</p>
                        </div>
                    </div>
                    <div className="col-lg-3">
                        <div className="team-img">
                            <img src={team2} alt=""/>
                        </div>
                        <div className="team-text">
                            <h2>tamim</h2>
                            <p>react developer</p>
                        </div>
                    </div>

                </div>
            </div>
        </div>
        


    )
}

export default Team;