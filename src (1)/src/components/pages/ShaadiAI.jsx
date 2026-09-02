// import React, { useState, useEffect, useRef } from "react";
// import axios from "../../services/api/axiosInstance";
// import styles from "./ShaadiAI.module.css";
// import { FaPaperPlane, FaMagic, FaUser, FaRobot, FaMapMarkerAlt, FaStar, FaTags, FaWallet, FaPlus, FaTrash, FaBars, FaTimes, FaComment } from "react-icons/fa";
// import { 
//     PersonalityQuizInline, 
//     CultureBlenderInline, 
//     ConflictResolverInline, 
//     TimelineGeneratorInline,
//     PersonalityQuizResult,
//     CultureBlenderResult,
//     ConflictResolverResult,
//     TimelineGeneratorResult
// } from "./ChatFeatures";

// const ShaadiAI = () => {
//     const INITIAL_MSG = {
//         role: "ai",
//         content: "Namaste! 🙏 I'm Shaadi AI, your personal wedding planning assistant.\n\nTell me what you're looking for — a venue, photographer, mehendi artist, decorator, DJ, or a full wedding plan?\n\n✨ Try these AI features:\n• /personality-quiz - Discover your wedding style\n• /culture-blender - Blend two cultures\n• /conflict-resolver - Resolve wedding decisions\n• /timeline-generator - Create your wedding timeline\n\n💡 Tip: You can also just say \"I want to take personality quiz\" or \"help me blend cultures\" and I'll understand!"
//     };

//     const [messages, setMessages] = useState([INITIAL_MSG]);
//     const [input, setInput] = useState("");
//     const [loading, setLoading] = useState(false);
//     const [chatList, setChatList] = useState([]);
//     const [activeChatId, setActiveChatId] = useState(null);
//     const [sidebarOpen, setSidebarOpen] = useState(true);
//     const [activeFeature, setActiveFeature] = useState(null);
//     const chatEndRef = useRef(null);
//     const textareaRef = useRef(null);

//     const isInitialState = messages.length === 1 && !activeChatId;

//     // Load chat list on mount
//     useEffect(() => {
//         fetchChatList();
        
//         // Add scroll padding to account for sticky header and sticky input
//         document.documentElement.style.scrollPaddingTop = "80px";
//         document.documentElement.style.scrollPaddingBottom = "120px";
        
//         return () => {
//             document.documentElement.style.scrollPaddingTop = "";
//             document.documentElement.style.scrollPaddingBottom = "";
//         };
//     }, []);

//     const fetchChatList = () => {
//         try {
//             const saved = localStorage.getItem('shaadi_ai_chats');
//             if (saved) {
//                 const parsed = JSON.parse(saved);
//                 parsed.sort((a, b) => b.updatedAt - a.updatedAt);
//                 setChatList(parsed);
//             }
//         } catch (err) {
//             console.error("Failed to load chats:", err);
//         }
//     };

//     const prevMessagesLength = useRef(messages.length);

//     const scrollToBottom = (behavior = "smooth") => {
//         if (chatEndRef.current) {
//             chatEndRef.current.scrollIntoView({ behavior, block: "end" });
//         }
//     };

//     useEffect(() => {
//         // Determine scroll behavior: 'auto' for initial load/switching chats, 'smooth' for new messages
//         const behavior = messages.length > prevMessagesLength.current ? "smooth" : "auto";
        
//         const timer = setTimeout(() => {
//             scrollToBottom(behavior);
//             prevMessagesLength.current = messages.length;
//         }, 100);

//         return () => clearTimeout(timer);
//     }, [messages, loading, activeChatId]);

//     const handleInput = (e) => {
//         setInput(e.target.value);
//         if (textareaRef.current) {
//             textareaRef.current.style.height = 'auto';
//             textareaRef.current.style.height = `${Math.min(textareaRef.current.scrollHeight, 200)}px`;
//         }
//     };

//     // Auto-save chat after each AI response to Local Storage
//     const handleFeatureComplete = (featureType, result) => {
//         if (result.error) {
//             const errorMessages = [...messages, {
//                 role: "ai",
//                 content: result.error
//             }];
//             setMessages(errorMessages);
//             setActiveFeature(null);
//             return;
//         }

//         const resultMessage = {
//             role: "ai",
//             content: `Here are your ${featureType.replace('-', ' ')} results! Feel free to ask me any questions about them.`,
//             featureResult: result,
//             featureType: featureType
//         };

//         const newMessages = [...messages, resultMessage];
//         setMessages(newMessages);
//         setActiveFeature(null);

//         // Auto-save
//         const newId = saveChat(newMessages, activeChatId);
//         if (!activeChatId) setActiveChatId(newId);
//     };

//     const saveChat = (updatedMessages, chatId) => {
//         try {
//             const firstUserMsg = updatedMessages.find(m => m.role === "user");
//             const title = firstUserMsg
//                 ? firstUserMsg.content.substring(0, 60) + (firstUserMsg.content.length > 60 ? "..." : "")
//                 : "New Chat";

//             const messagesToSave = updatedMessages.map(m => ({
//                 role: m.role,
//                 content: m.content,
//                 ...(m.vendors && { vendors: m.vendors }),
//                 ...(m.comparisons && m.comparisons.length > 0 && { comparisons: m.comparisons }),
//                 ...(m.budget_breakdown && Object.keys(m.budget_breakdown).length > 0 && { budget_breakdown: m.budget_breakdown }),
//                 ...(m.suggestions && m.suggestions.length > 0 && { suggestions: m.suggestions }),
//                 ...(m.featureType && { featureType: m.featureType }),
//                 ...(m.featureResult && { featureResult: m.featureResult })
//             }));

//             let savedChats = [];
//             const saved = localStorage.getItem('shaadi_ai_chats');
//             if (saved) savedChats = JSON.parse(saved);

//             let newChatId = chatId;

//             if (chatId) {
//                 const index = savedChats.findIndex(c => c.id === chatId);
//                 if (index !== -1) {
//                     savedChats[index].title = title;
//                     savedChats[index].messages = messagesToSave;
//                     savedChats[index].updatedAt = Date.now();
//                 } else {
//                     savedChats.push({ id: chatId, title, messages: messagesToSave, updatedAt: Date.now() });
//                 }
//             } else {
//                 newChatId = Date.now().toString() + Math.random().toString(36).substring(7);
//                 savedChats.push({ id: newChatId, title, messages: messagesToSave, updatedAt: Date.now() });
//                 setActiveChatId(newChatId);
//             }

//             localStorage.setItem('shaadi_ai_chats', JSON.stringify(savedChats));
//             fetchChatList();
//             return newChatId;
//         } catch (err) {
//             console.error("Failed to save chat:", err);
//             return chatId;
//         }
//     };

//     const handleSend = async (customMessage = null) => {
//         const userMsg = customMessage || input.trim();
//         if (!userMsg) return;

//         // Check for slash commands
//         const slashCommands = {
//             '/personality-quiz': 'personality-quiz',
//             '/culture-blender': 'culture-blender',
//             '/conflict-resolver': 'conflict-resolver',
//             '/timeline-generator': 'timeline-generator'
//         };

//         const command = Object.keys(slashCommands).find(cmd => userMsg.toLowerCase().startsWith(cmd));
        
//         if (command) {
//             const updatedMessages = [...messages, { 
//                 role: "user", 
//                 content: userMsg 
//             }, {
//                 role: "ai",
//                 content: `Opening ${slashCommands[command].replace('-', ' ')}...`,
//                 featureType: slashCommands[command]
//             }];
//             setMessages(updatedMessages);
//             setActiveFeature(slashCommands[command]);
//             if (!customMessage) setInput("");
//             if (textareaRef.current) textareaRef.current.style.height = 'auto';
            
//             // Auto-save
//             const newId = saveChat(updatedMessages, activeChatId);
//             if (!activeChatId) setActiveChatId(newId);
//             return;
//         }

//         // Natural language keyword detection
//         const lowerMsg = userMsg.toLowerCase();
        
//         // Personality Quiz keywords
//         const personalityKeywords = [
//             'personality quiz', 'personality test', 'wedding style', 'wedding quiz',
//             'discover my style', 'find my style', 'what style', 'wedding personality',
//             'take quiz', 'take the quiz', 'style quiz', 'vibe quiz'
//         ];
        
//         // Culture Blender keywords
//         const cultureKeywords = [
//             'culture blend', 'blend culture', 'culture blender', 'mix culture',
//             'fusion wedding', 'multi cultural', 'multicultural', 'two culture',
//             'combine culture', 'merge culture', 'cultural fusion', 'blend my culture'
//         ];
        
//         // Conflict Resolver keywords
//         const conflictKeywords = [
//             'conflict', 'disagree', 'disagreement', 'resolve conflict', 'conflict resolver',
//             'husband wife conflict', 'partner conflict', 'couple conflict',
//             'we disagree', 'can\'t agree', 'cannot agree', 'help us decide',
//             'mediate', 'resolve decision', 'solve conflict', 'fix conflict'
//         ];
        
//         // Timeline Generator keywords
//         const timelineKeywords = [
//             'timeline', 'schedule', 'wedding timeline', 'day timeline', 'event timeline',
//             'generate timeline', 'create timeline', 'make timeline', 'plan timeline',
//             'wedding schedule', 'event schedule', 'day schedule', 'timing',
//             'time management', 'wedding day plan'
//         ];

//         let detectedFeature = null;
//         let featureName = '';

//         // Check for personality quiz
//         if (personalityKeywords.some(keyword => lowerMsg.includes(keyword))) {
//             detectedFeature = 'personality-quiz';
//             featureName = 'Personality Quiz';
//         }
//         // Check for culture blender
//         else if (cultureKeywords.some(keyword => lowerMsg.includes(keyword))) {
//             detectedFeature = 'culture-blender';
//             featureName = 'Culture Blender';
//         }
//         // Check for conflict resolver
//         else if (conflictKeywords.some(keyword => lowerMsg.includes(keyword))) {
//             detectedFeature = 'conflict-resolver';
//             featureName = 'Conflict Resolver';
//         }
//         // Check for timeline generator
//         else if (timelineKeywords.some(keyword => lowerMsg.includes(keyword))) {
//             detectedFeature = 'timeline-generator';
//             featureName = 'Timeline Generator';
//         }

//         // If a feature was detected, activate it
//         if (detectedFeature) {
//             const updatedMessages = [...messages, { 
//                 role: "user", 
//                 content: userMsg 
//             }, {
//                 role: "ai",
//                 content: `I detected you want to use the ${featureName}! Opening it for you...`,
//                 featureType: detectedFeature
//             }];
//             setMessages(updatedMessages);
//             setActiveFeature(detectedFeature);
//             if (!customMessage) setInput("");
//             if (textareaRef.current) textareaRef.current.style.height = 'auto';
            
//             // Auto-save
//             const newId = saveChat(updatedMessages, activeChatId);
//             if (!activeChatId) setActiveChatId(newId);
//             return;
//         }

//         const updatedMessages = [...messages, { role: "user", content: userMsg }];
//         setMessages(updatedMessages);
//         if (!customMessage) setInput("");
//         if (textareaRef.current) textareaRef.current.style.height = 'auto';
//         setLoading(true);

//         try {
//             const historyForBackend = updatedMessages
//                 .filter((_, i) => i > 0)
//                 .filter(m => !m.featureType) // Exclude feature messages from history
//                 .map(m => ({ role: m.role === "ai" ? "assistant" : "user", content: m.content }));

//             const response = await axios.post("/ai/chat", {
//                 message: userMsg,
//                 conversationHistory: historyForBackend
//             });
//             const data = response.data;

//             const newMessages = [...updatedMessages, {
//                 role: "ai",
//                 content: data.summary,
//                 vendors: data.vendors,
//                 comparisons: data.comparisons,
//                 suggestions: data.suggestions,
//                 budget_breakdown: data.budget_breakdown
//             }];

//             setMessages(newMessages);

//             // Auto-save to local storage
//             const newId = saveChat(newMessages, activeChatId);
//             if (!activeChatId) setActiveChatId(newId);

//         } catch (error) {
//             console.error("AI Error:", error);
//             const errorMessages = [...updatedMessages, {
//                 role: "ai",
//                 content: "Oops! Something went wrong. Please try again in a moment. 🙏"
//             }];
//             setMessages(errorMessages);
//         } finally {
//             setLoading(false);
//         }
//     };

//     const handleKeyDown = (e) => {
//         if (e.key === 'Enter' && !e.shiftKey) {
//             e.preventDefault();
//             handleSend();
//         }
//     };

//     const handleNewChat = () => {
//         setMessages([INITIAL_MSG]);
//         setActiveChatId(null);
//         setInput("");
//     };

//     const handleLoadChat = (chatId) => {
//         try {
//             const saved = localStorage.getItem('shaadi_ai_chats');
//             if (saved) {
//                 const parsed = JSON.parse(saved);
//                 const chat = parsed.find(c => c.id === chatId);
//                 if (chat) {
//                     setMessages(chat.messages || [INITIAL_MSG]);
//                     setActiveChatId(chatId);
//                     if (window.innerWidth < 768) setSidebarOpen(false);
//                 }
//             }
//         } catch (err) {
//             console.error("Failed to load chat:", err);
//         }
//     };

//     const handleDeleteChat = (e, chatId) => {
//         e.stopPropagation();
//         try {
//             const saved = localStorage.getItem('shaadi_ai_chats');
//             if (saved) {
//                 let parsed = JSON.parse(saved);
//                 parsed = parsed.filter(c => c.id !== chatId);
//                 localStorage.setItem('shaadi_ai_chats', JSON.stringify(parsed));
                
//                 if (activeChatId === chatId) {
//                     handleNewChat();
//                 }
//                 fetchChatList();
//             }
//         } catch (err) {
//             console.error("Failed to delete chat:", err);
//         }
//     };

//     const formatBudget = (amount) => {
//         if (!amount) return "₹0";
//         return `₹${Number(amount).toLocaleString('en-IN')}`;
//     };

//     const renderInputArea = () => (
//         <div className={styles.inputWrapper}>
//             <div className={styles.inputBox}>
//                 <textarea
//                     ref={textareaRef}
//                     value={input}
//                     onChange={handleInput}
//                     onKeyDown={handleKeyDown}
//                     placeholder="Ask anything about your wedding..."
//                     rows={1}
//                 />
//                 <div className={styles.inputRight}>
//                     <button
//                         className={`${styles.submitBtn} ${input.trim() ? styles.activeSubmit : ''}`}
//                         onClick={() => handleSend()}
//                         disabled={loading || !input.trim()}
//                     >
//                         <FaPaperPlane />
//                     </button>
//                 </div>
//             </div>
//         </div>
//     );

//     // ======= SIDEBAR =======
//     const renderSidebar = () => (
//         <div className={`${styles.sidebar} ${sidebarOpen ? styles.sidebarOpen : styles.sidebarClosed}`}>
//             <div className={styles.sidebarHeader}>
//                 <h3>Shaadi AI</h3>
//                 <button className={styles.closeSidebar} onClick={() => setSidebarOpen(false)}>
//                     <FaTimes />
//                 </button>
//             </div>

//             <button className={styles.newChatBtn} onClick={handleNewChat}>
//                 <FaPlus /> New Chat
//             </button>

//             <div className={styles.chatListSection}>
//                 <span className={styles.chatListLabel}>Recent</span>
//                 <div className={styles.chatList}>
//                     {chatList.map(chat => (
//                         <div
//                             key={chat.id}
//                             className={`${styles.chatListItem} ${activeChatId === chat.id ? styles.chatListItemActive : ''}`}
//                             onClick={() => handleLoadChat(chat.id)}
//                         >
//                             <FaComment className={styles.chatIcon} />
//                             <span className={styles.chatTitle}>{chat.title}</span>
//                             <button
//                                 className={styles.deleteChatBtn}
//                                 onClick={(e) => handleDeleteChat(e, chat.id)}
//                             >
//                                 <FaTrash />
//                             </button>
//                         </div>
//                     ))}
//                     {chatList.length === 0 && (
//                         <p className={styles.noChats}>No saved chats yet</p>
//                     )}
//                 </div>
//             </div>
//         </div>
//     );

//     // ======= HOME SCREEN (Initial State) =======
//     if (isInitialState) {
//         return (
//             <div className={styles.appLayout}>
//                 {renderSidebar()}
//                 <div className={styles.mainArea}>
//                     {!sidebarOpen && (
//                         <button className={styles.menuBtn} onClick={() => setSidebarOpen(true)}>
//                             <FaBars />
//                         </button>
//                     )}
//                     <div className={styles.homeContainer}>
//                         <div className={styles.homeContent}>
//                             <h1 className={styles.homeTitle}>Shaadi AI</h1>

//                             {renderInputArea()}

//                             <div className={styles.suggestionsWrapper}>
//                                 <div className={styles.suggestionsHeader}>
//                                     <FaMagic /> Try Shaadi AI
//                                 </div>
//                                 <div className={styles.suggestionGrid}>
//                                     <div className={styles.suggestionPill} onClick={() => handleSend("Plan a full wedding in Mumbai for 15 lakhs")}>
//                                         <span>💍 Plan Wedding</span>
//                                         <p>Plan a full wedding in Mumbai for 15 lakhs</p>
//                                     </div>
//                                     <div className={styles.suggestionPill} onClick={() => handleSend("Find me a bohemian venue in Delhi")}>
//                                         <span>🏰 Bohemian Venue</span>
//                                         <p>Find me a bohemian venue in Delhi</p>
//                                     </div>
//                                     <div className={styles.suggestionPill} onClick={() => handleSend("/personality-quiz")}>
//                                         <span>💕 Personality Quiz</span>
//                                         <p>Discover your unique wedding style</p>
//                                     </div>
//                                     <div className={styles.suggestionPill} onClick={() => handleSend("/culture-blender")}>
//                                         <span>✨ Culture Blender</span>
//                                         <p>Blend two cultures beautifully</p>
//                                     </div>
//                                     <div className={styles.suggestionPill} onClick={() => handleSend("/conflict-resolver")}>
//                                         <span>⚖️ Conflict Resolver</span>
//                                         <p>Resolve wedding decisions together</p>
//                                     </div>
//                                     <div className={styles.suggestionPill} onClick={() => handleSend("/timeline-generator")}>
//                                         <span>📅 Timeline Generator</span>
//                                         <p>Create your wedding timeline</p>
//                                     </div>
//                                 </div>
//                             </div>
//                         </div>
//                     </div>
//                 </div>
//             </div>
//         );
//     }

//     // ======= CHAT VIEW =======
//     return (
//         <div className={styles.appLayout}>
//             {renderSidebar()}
//             <div className={styles.mainArea}>
//                 <div className={styles.chatHeader}>
//                     {!sidebarOpen && (
//                         <button className={styles.menuBtn} onClick={() => setSidebarOpen(true)}>
//                             <FaBars />
//                         </button>
//                     )}
//                     <h2>Shaadi AI</h2>
//                 </div>

//                 <div className={styles.chatMessages}>
//                     <div className={styles.messagesMaxWidth}>
//                         {messages.map((msg, index) => {
//                             if (index === 0) return null;

//                             return (
//                                 <div key={index} className={`${styles.messageBlock} ${msg.role === 'user' ? styles.userBlock : styles.aiBlock}`}>
//                                     {msg.role === 'ai' && (
//                                         <div className={styles.avatar}>
//                                             <FaMagic />
//                                         </div>
//                                     )}
//                                     <div className={styles.messageContent}>
//                                         {msg.role === 'user' ? (
//                                             <div className={styles.userText}>{msg.content}</div>
//                                         ) : (
//                                             <>
//                                                 <div className={styles.aiText}>
//                                                     {msg.content?.split('\n').map((line, i) => (
//                                                         <span key={i}>{line}<br /></span>
//                                                     ))}
//                                                 </div>

//                                                 {/* Render inline feature forms */}
//                                                 {msg.featureType === 'personality-quiz' && !msg.featureResult && (
//                                                     <PersonalityQuizInline onComplete={(result) => handleFeatureComplete('personality-quiz', result)} />
//                                                 )}
//                                                 {msg.featureType === 'culture-blender' && !msg.featureResult && (
//                                                     <CultureBlenderInline onComplete={(result) => handleFeatureComplete('culture-blender', result)} />
//                                                 )}
//                                                 {msg.featureType === 'conflict-resolver' && !msg.featureResult && (
//                                                     <ConflictResolverInline onComplete={(result) => handleFeatureComplete('conflict-resolver', result)} />
//                                                 )}
//                                                 {msg.featureType === 'timeline-generator' && !msg.featureResult && (
//                                                     <TimelineGeneratorInline onComplete={(result) => handleFeatureComplete('timeline-generator', result)} />
//                                                 )}

//                                                 {/* Render feature results */}
//                                                 {msg.featureResult && msg.featureType === 'personality-quiz' && (
//                                                     <PersonalityQuizResult result={msg.featureResult} />
//                                                 )}
//                                                 {msg.featureResult && msg.featureType === 'culture-blender' && (
//                                                     <CultureBlenderResult result={msg.featureResult} />
//                                                 )}
//                                                 {msg.featureResult && msg.featureType === 'conflict-resolver' && (
//                                                     <ConflictResolverResult result={msg.featureResult} />
//                                                 )}
//                                                 {msg.featureResult && msg.featureType === 'timeline-generator' && (
//                                                     <TimelineGeneratorResult result={msg.featureResult} />
//                                                 )}

//                                                 {msg.budget_breakdown && Object.keys(msg.budget_breakdown).length > 0 && (
//                                                     <div className={styles.budgetBreakdown}>
//                                                         <div className={styles.budgetTitle}>
//                                                             <FaWallet /> Budget Breakdown
//                                                         </div>
//                                                         <div className={styles.budgetGrid}>
//                                                             {Object.entries(msg.budget_breakdown).map(([cat, amt]) => (
//                                                                 <div key={cat} className={styles.budgetItem}>
//                                                                     <span className={styles.budgetCategory}>{cat}</span>
//                                                                     <span className={styles.budgetAmount}>{formatBudget(amt)}</span>
//                                                                 </div>
//                                                             ))}
//                                                         </div>
//                                                     </div>
//                                                 )}

//                                                 {msg.vendors && msg.vendors.length > 0 && (
//                                                     <div className={styles.vendorsContainer}>
//                                                         {msg.vendors.map((vendor, i) => (
//                                                             <div 
//                                                                 key={i} 
//                                                                 className={styles.vendorCard}
//                                                                 onClick={() => {
//                                                                     if (vendor.id) {
//                                                                         window.location.href = `/details/info/${vendor.id}`;
//                                                                     }
//                                                                 }}
//                                                                 style={{ cursor: vendor.id ? 'pointer' : 'default' }}
//                                                             >
//                                                                 {vendor.image && (
//                                                                     <div className={styles.vendorImage}>
//                                                                         <img
//                                                                             src={vendor.image}
//                                                                             alt={vendor.name}
//                                                                             onError={e => { e.currentTarget.parentElement.style.display = 'none'; }}
//                                                                             style={{ width: '100%', height: '160px', objectFit: 'cover', borderRadius: '8px 8px 0 0', display: 'block' }}
//                                                                         />
//                                                                     </div>
//                                                                 )}
//                                                                 <div className={styles.vendorHeader}>
//                                                                     <h4>{vendor.name}</h4>
//                                                                     <span className={styles.vendorCategory}>{vendor.category}</span>
//                                                                 </div>
//                                                                 <div className={styles.vendorDetails}>
//                                                                     <p><FaMapMarkerAlt /> {vendor.location}</p>
//                                                                     <p className={styles.price}>{vendor.price_range}</p>
//                                                                     <p><FaStar className={styles.starIcon} /> {vendor.rating}</p>
//                                                                 </div>
//                                                                 <div className={styles.vendorWhy}>
//                                                                     <FaTags /> <span>{vendor.why_recommended?.join(" • ")}</span>
//                                                                 </div>
//                                                             </div>
//                                                         ))}
//                                                     </div>
//                                                 )}

//                                                 {msg.comparisons && msg.comparisons.length > 0 && (
//                                                     <div className={styles.comparisonsContainer}>
//                                                         <div className={styles.budgetTitle}>
//                                                             <FaMagic /> Auto-Comparison
//                                                         </div>
//                                                         {msg.comparisons.map((comp, i) => (
//                                                             <div key={i} className={styles.comparisonCard}>
//                                                                 <div className={styles.comparisonGrid}>
//                                                                     <div className={styles.compCol}>
//                                                                         <h4>{comp.vendor_1.name}</h4>
//                                                                         <p><strong>Price:</strong> {comp.vendor_1.price}</p>
//                                                                         <p><strong>Capacity:</strong> {comp.vendor_1.capacity}</p>
//                                                                         <p><strong>Rating:</strong> {comp.vendor_1.rating}</p>
//                                                                         <p><strong>Setup:</strong> {comp.vendor_1.indoor_outdoor}</p>
//                                                                     </div>
//                                                                     <div className={styles.compVs}>VS</div>
//                                                                     <div className={styles.compCol}>
//                                                                         <h4>{comp.vendor_2.name}</h4>
//                                                                         <p><strong>Price:</strong> {comp.vendor_2.price}</p>
//                                                                         <p><strong>Capacity:</strong> {comp.vendor_2.capacity}</p>
//                                                                         <p><strong>Rating:</strong> {comp.vendor_2.rating}</p>
//                                                                         <p><strong>Setup:</strong> {comp.vendor_2.indoor_outdoor}</p>
//                                                                     </div>
//                                                                 </div>
//                                                                 <div className={styles.compRecommendation}>
//                                                                     💡 {comp.recommendation}
//                                                                 </div>
//                                                             </div>
//                                                         ))}
//                                                     </div>
//                                                 )}

//                                                 {msg.suggestions && msg.suggestions.length > 0 && (
//                                                     <div className={styles.suggestionsContainer}>
//                                                         {msg.suggestions.map((sug, i) => (
//                                                             <div key={i} className={styles.suggestionAlert}>
//                                                                 ✨ {sug}
//                                                             </div>
//                                                         ))}
//                                                     </div>
//                                                 )}
//                                             </>
//                                         )}
//                                     </div>
//                                 </div>
//                             )
//                         })}

//                         {loading && (
//                             <div className={`${styles.messageBlock} ${styles.aiBlock}`}>
//                                 <div className={styles.avatar}><FaMagic /></div>
//                                 <div className={styles.loadingBubble}>
//                                     <div className={styles.dotPulse}></div>
//                                 </div>
//                             </div>
//                         )}
//                         <div ref={chatEndRef} className={styles.chatEndMarker} />
//                     </div>
//                 </div>

//                 <div className={styles.chatInputWrapper}>
//                     <div className={styles.chatInputMaxWidth}>
//                         {renderInputArea()}
//                     </div>
//                 </div>
//             </div>
//         </div>
//     );
// };

// export default ShaadiAI;


import React, { useState, useEffect, useRef } from "react";
import axios from "../../services/api/axiosInstance";
import styles from "./ShaadiAI.module.css";
import { FaPaperPlane, FaMagic, FaUser, FaRobot, FaMapMarkerAlt, FaTags, FaWallet, FaPlus, FaTrash, FaBars, FaTimes, FaComment } from "react-icons/fa";
import { 
    PersonalityQuizInline, 
    CultureBlenderInline, 
    ConflictResolverInline, 
    TimelineGeneratorInline,
    PersonalityQuizResult,
    CultureBlenderResult,
    ConflictResolverResult,
    TimelineGeneratorResult
} from "./ChatFeatures";

const ShaadiAI = () => {
    const INITIAL_MSG = {
        role: "ai",
        content: "Namaste! 🙏 I'm Shaadi AI, your personal wedding planning assistant.\n\nTell me what you're looking for — a venue, photographer, mehendi artist, decorator, DJ, or a full wedding plan?\n\n✨ Try these AI features:\n• /personality-quiz - Discover your wedding style\n• /culture-blender - Blend two cultures\n• /conflict-resolver - Resolve wedding decisions\n• /timeline-generator - Create your wedding timeline\n\n💡 Tip: You can also just say \"I want to take personality quiz\" or \"help me blend cultures\" and I'll understand!"
    };

    const [messages, setMessages] = useState([INITIAL_MSG]);
    const [input, setInput] = useState("");
    const [loading, setLoading] = useState(false);
    const [chatList, setChatList] = useState([]);
    const [activeChatId, setActiveChatId] = useState(null);
    const [sidebarOpen, setSidebarOpen] = useState(true);
    const [activeFeature, setActiveFeature] = useState(null);
    const chatEndRef = useRef(null);
    const textareaRef = useRef(null);

    const isInitialState = messages.length === 1 && !activeChatId;

    // Load chat list on mount
    useEffect(() => {
        fetchChatList();
    }, []);

    // scroll-padding used to be set on the document here, to stop scrollIntoView
    // from parking a new message behind the sticky header and sticky input bar.
    //
    // It also applied to the browser's own "keep the caret visible" scrolling.
    // The input bar is position: sticky; bottom: 0, so with a 120px bottom
    // padding the browser decided the caret was obscured, scrolled to lift it
    // clear, and the bar moved down with the page — every keystroke, which is
    // why the chat jumped while typing.
    //
    // The clearance is only ever needed by the one element we scroll to, so it
    // lives on that element as scroll-margin instead. See .chatEndMarker.

    const fetchChatList = () => {
        try {
            const saved = localStorage.getItem('shaadi_ai_chats');
            if (saved) {
                const parsed = JSON.parse(saved);
                parsed.sort((a, b) => b.updatedAt - a.updatedAt);
                setChatList(parsed);
            }
        } catch (err) {
            console.error("Failed to load chats:", err);
        }
    };

    const prevMessagesLength = useRef(messages.length);

    const scrollToBottom = (behavior = "smooth") => {
        if (chatEndRef.current) {
            chatEndRef.current.scrollIntoView({ behavior, block: "end" });
        }
    };

    useEffect(() => {
        // Determine scroll behavior: 'auto' for initial load/switching chats, 'smooth' for new messages
        const behavior = messages.length > prevMessagesLength.current ? "smooth" : "auto";
        
        const timer = setTimeout(() => {
            scrollToBottom(behavior);
            prevMessagesLength.current = messages.length;
        }, 100);

        return () => clearTimeout(timer);
    }, [messages, loading, activeChatId]);

    const handleInput = (e) => {
        setInput(e.target.value);

        const el = textareaRef.current;
        if (!el) return;

        // The textarea grows with its content, and measuring that requires
        // collapsing it to `auto` first — scrollHeight cannot report a smaller
        // height than the element already has.
        //
        // But collapsing it shortens the page for one frame, and the browser
        // compensates by scrolling. On every keystroke that reads as the chat
        // jumping around while you type. So the scroll position is captured
        // before the measurement and put back after it, and the height is only
        // written when it actually changed.
        const scrollY = window.scrollY;
        const previous = el.style.height;

        el.style.height = 'auto';
        const next = `${Math.min(el.scrollHeight, 200)}px`;
        el.style.height = next === previous ? previous : next;

        if (window.scrollY !== scrollY) window.scrollTo({ top: scrollY });
    };

    // Auto-save chat after each AI response to Local Storage
    const handleFeatureComplete = (featureType, result) => {
        if (result.error) {
            const errorMessages = [...messages, {
                role: "ai",
                content: result.error
            }];
            setMessages(errorMessages);
            setActiveFeature(null);
            return;
        }

        const resultMessage = {
            role: "ai",
            content: `Here are your ${featureType.replace('-', ' ')} results! Feel free to ask me any questions about them.`,
            featureResult: result,
            featureType: featureType
        };

        const newMessages = [...messages, resultMessage];
        setMessages(newMessages);
        setActiveFeature(null);

        // Auto-save
        const newId = saveChat(newMessages, activeChatId);
        if (!activeChatId) setActiveChatId(newId);
    };

    const saveChat = (updatedMessages, chatId) => {
        try {
            const firstUserMsg = updatedMessages.find(m => m.role === "user");
            const title = firstUserMsg
                ? firstUserMsg.content.substring(0, 60) + (firstUserMsg.content.length > 60 ? "..." : "")
                : "New Chat";

            const messagesToSave = updatedMessages.map(m => ({
                role: m.role,
                content: m.content,
                ...(m.vendors && { vendors: m.vendors }),
                ...(m.products && m.products.length > 0 && { products: m.products }),
                ...(m.orders && m.orders.length > 0 && { orders: m.orders }),
                ...(m.comparisons && m.comparisons.length > 0 && { comparisons: m.comparisons }),
                ...(m.budget_breakdown && Object.keys(m.budget_breakdown).length > 0 && { budget_breakdown: m.budget_breakdown }),
                ...(m.suggestions && m.suggestions.length > 0 && { suggestions: m.suggestions }),
                ...(m.featureType && { featureType: m.featureType }),
                ...(m.featureResult && { featureResult: m.featureResult })
            }));

            let savedChats = [];
            const saved = localStorage.getItem('shaadi_ai_chats');
            if (saved) savedChats = JSON.parse(saved);

            let newChatId = chatId;

            if (chatId) {
                const index = savedChats.findIndex(c => c.id === chatId);
                if (index !== -1) {
                    savedChats[index].title = title;
                    savedChats[index].messages = messagesToSave;
                    savedChats[index].updatedAt = Date.now();
                } else {
                    savedChats.push({ id: chatId, title, messages: messagesToSave, updatedAt: Date.now() });
                }
            } else {
                newChatId = Date.now().toString() + Math.random().toString(36).substring(7);
                savedChats.push({ id: newChatId, title, messages: messagesToSave, updatedAt: Date.now() });
                setActiveChatId(newChatId);
            }

            localStorage.setItem('shaadi_ai_chats', JSON.stringify(savedChats));
            fetchChatList();
            return newChatId;
        } catch (err) {
            console.error("Failed to save chat:", err);
            return chatId;
        }
    };

    const handleSend = async (customMessage = null) => {
        const userMsg = customMessage || input.trim();
        if (!userMsg) return;

        // Check for slash commands
        const slashCommands = {
            '/personality-quiz': 'personality-quiz',
            '/culture-blender': 'culture-blender',
            '/conflict-resolver': 'conflict-resolver',
            '/timeline-generator': 'timeline-generator'
        };

        const command = Object.keys(slashCommands).find(cmd => userMsg.toLowerCase().startsWith(cmd));
        
        if (command) {
            const updatedMessages = [...messages, { 
                role: "user", 
                content: userMsg 
            }, {
                role: "ai",
                content: `Opening ${slashCommands[command].replace('-', ' ')}...`,
                featureType: slashCommands[command]
            }];
            setMessages(updatedMessages);
            setActiveFeature(slashCommands[command]);
            if (!customMessage) setInput("");
            if (textareaRef.current) textareaRef.current.style.height = 'auto';
            
            // Auto-save
            const newId = saveChat(updatedMessages, activeChatId);
            if (!activeChatId) setActiveChatId(newId);
            return;
        }

        // Natural language keyword detection
        const lowerMsg = userMsg.toLowerCase();
        
        // Personality Quiz keywords
        const personalityKeywords = [
            'personality quiz', 'personality test', 'wedding style', 'wedding quiz',
            'discover my style', 'find my style', 'what style', 'wedding personality',
            'take quiz', 'take the quiz', 'style quiz', 'vibe quiz'
        ];
        
        // Culture Blender keywords
        const cultureKeywords = [
            'culture blend', 'blend culture', 'culture blender', 'mix culture',
            'fusion wedding', 'multi cultural', 'multicultural', 'two culture',
            'combine culture', 'merge culture', 'cultural fusion', 'blend my culture'
        ];
        
        // Conflict Resolver keywords
        const conflictKeywords = [
            'conflict', 'disagree', 'disagreement', 'resolve conflict', 'conflict resolver',
            'husband wife conflict', 'partner conflict', 'couple conflict',
            'we disagree', 'can\'t agree', 'cannot agree', 'help us decide',
            'mediate', 'resolve decision', 'solve conflict', 'fix conflict'
        ];
        
        // Timeline Generator keywords
        const timelineKeywords = [
            'timeline', 'schedule', 'wedding timeline', 'day timeline', 'event timeline',
            'generate timeline', 'create timeline', 'make timeline', 'plan timeline',
            'wedding schedule', 'event schedule', 'day schedule', 'timing',
            'time management', 'wedding day plan'
        ];

        let detectedFeature = null;
        let featureName = '';

        // Check for personality quiz
        if (personalityKeywords.some(keyword => lowerMsg.includes(keyword))) {
            detectedFeature = 'personality-quiz';
            featureName = 'Personality Quiz';
        }
        // Check for culture blender
        else if (cultureKeywords.some(keyword => lowerMsg.includes(keyword))) {
            detectedFeature = 'culture-blender';
            featureName = 'Culture Blender';
        }
        // Check for conflict resolver
        else if (conflictKeywords.some(keyword => lowerMsg.includes(keyword))) {
            detectedFeature = 'conflict-resolver';
            featureName = 'Conflict Resolver';
        }
        // Check for timeline generator
        else if (timelineKeywords.some(keyword => lowerMsg.includes(keyword))) {
            detectedFeature = 'timeline-generator';
            featureName = 'Timeline Generator';
        }

        // If a feature was detected, activate it
        if (detectedFeature) {
            const updatedMessages = [...messages, { 
                role: "user", 
                content: userMsg 
            }, {
                role: "ai",
                content: `I detected you want to use the ${featureName}! Opening it for you...`,
                featureType: detectedFeature
            }];
            setMessages(updatedMessages);
            setActiveFeature(detectedFeature);
            if (!customMessage) setInput("");
            if (textareaRef.current) textareaRef.current.style.height = 'auto';
            
            // Auto-save
            const newId = saveChat(updatedMessages, activeChatId);
            if (!activeChatId) setActiveChatId(newId);
            return;
        }

        const updatedMessages = [...messages, { role: "user", content: userMsg }];
        setMessages(updatedMessages);
        if (!customMessage) setInput("");
        if (textareaRef.current) textareaRef.current.style.height = 'auto';
        setLoading(true);

        try {
            const historyForBackend = updatedMessages
                .filter((_, i) => i > 0)
                .filter(m => !m.featureType) // Exclude feature messages from history
                .map(m => ({ role: m.role === "ai" ? "assistant" : "user", content: m.content }));

            const response = await axios.post("/ai/chat", {
                message: userMsg,
                conversationHistory: historyForBackend
            });
            const data = response.data;

            const newMessages = [...updatedMessages, {
                role: "ai",
                content: data.summary,
                vendors: data.vendors,
                products: data.products,
                orders: data.orders,
                comparisons: data.comparisons,
                suggestions: data.suggestions,
                budget_breakdown: data.budget_breakdown
            }];

            setMessages(newMessages);

            // Auto-save to local storage
            const newId = saveChat(newMessages, activeChatId);
            if (!activeChatId) setActiveChatId(newId);

        } catch (error) {
            console.error("AI Error:", error);
            const errorMessages = [...updatedMessages, {
                role: "ai",
                content: "Oops! Something went wrong. Please try again in a moment. 🙏"
            }];
            setMessages(errorMessages);
        } finally {
            setLoading(false);
        }
    };

    const handleKeyDown = (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            handleSend();
        }
    };

    const handleNewChat = () => {
        setMessages([INITIAL_MSG]);
        setActiveChatId(null);
        setInput("");
    };

    const handleLoadChat = (chatId) => {
        try {
            const saved = localStorage.getItem('shaadi_ai_chats');
            if (saved) {
                const parsed = JSON.parse(saved);
                const chat = parsed.find(c => c.id === chatId);
                if (chat) {
                    setMessages(chat.messages || [INITIAL_MSG]);
                    setActiveChatId(chatId);
                    if (window.innerWidth < 768) setSidebarOpen(false);
                }
            }
        } catch (err) {
            console.error("Failed to load chat:", err);
        }
    };

    const handleDeleteChat = (e, chatId) => {
        e.stopPropagation();
        try {
            const saved = localStorage.getItem('shaadi_ai_chats');
            if (saved) {
                let parsed = JSON.parse(saved);
                parsed = parsed.filter(c => c.id !== chatId);
                localStorage.setItem('shaadi_ai_chats', JSON.stringify(parsed));
                
                if (activeChatId === chatId) {
                    handleNewChat();
                }
                fetchChatList();
            }
        } catch (err) {
            console.error("Failed to delete chat:", err);
        }
    };

    const formatBudget = (amount) => {
        if (!amount) return "₹0";
        return `₹${Number(amount).toLocaleString('en-IN')}`;
    };

    const renderInputArea = () => (
        <div className={styles.inputWrapper}>
            <div className={styles.inputBox}>
                <textarea
                    ref={textareaRef}
                    value={input}
                    onChange={handleInput}
                    onKeyDown={handleKeyDown}
                    placeholder="Ask anything about your wedding..."
                    rows={1}
                />
                <div className={styles.inputRight}>
                    <button
                        className={`${styles.submitBtn} ${input.trim() ? styles.activeSubmit : ''}`}
                        onClick={() => handleSend()}
                        disabled={loading || !input.trim()}
                    >
                        <FaPaperPlane />
                    </button>
                </div>
            </div>
        </div>
    );

    // ======= SIDEBAR =======
    const renderSidebar = () => (
        <div className={`${styles.sidebar} ${sidebarOpen ? styles.sidebarOpen : styles.sidebarClosed}`}>
            <div className={styles.sidebarHeader}>
                <h3>Shaadi AI</h3>
                <button className={styles.closeSidebar} onClick={() => setSidebarOpen(false)}>
                    <FaTimes />
                </button>
            </div>

            <button className={styles.newChatBtn} onClick={handleNewChat}>
                <FaPlus /> New Chat
            </button>

            <div className={styles.chatListSection}>
                <span className={styles.chatListLabel}>Recent</span>
                <div className={styles.chatList}>
                    {chatList.map(chat => (
                        <div
                            key={chat.id}
                            className={`${styles.chatListItem} ${activeChatId === chat.id ? styles.chatListItemActive : ''}`}
                            onClick={() => handleLoadChat(chat.id)}
                        >
                            <FaComment className={styles.chatIcon} />
                            <span className={styles.chatTitle}>{chat.title}</span>
                            <button
                                className={styles.deleteChatBtn}
                                onClick={(e) => handleDeleteChat(e, chat.id)}
                            >
                                <FaTrash />
                            </button>
                        </div>
                    ))}
                    {chatList.length === 0 && (
                        <p className={styles.noChats}>No saved chats yet</p>
                    )}
                </div>
            </div>
        </div>
    );

    // ======= HOME SCREEN (Initial State) =======
    if (isInitialState) {
        return (
            <div className={styles.appLayout}>
                {renderSidebar()}
                <div className={styles.mainArea}>
                    {!sidebarOpen && (
                        <button className={styles.menuBtn} onClick={() => setSidebarOpen(true)}>
                            <FaBars />
                        </button>
                    )}
                    <div className={styles.homeContainer}>
                        <div className={styles.homeContent}>
                            {/* Logo only — the mark already carries the wordmark, so the
                                alt text is what gives this heading its accessible name. */}
                            <h1 className={styles.homeTitle}>
                                <img
                                    src="/logo-no-bg.png"
                                    alt="Shaadi AI by HappyWedz"
                                    className={styles.homeTitleLogo}
                                    width="128"
                                    height="128"
                                    decoding="async"
                                />
                            </h1>

                            {renderInputArea()}

                            <div className={styles.suggestionsWrapper}>
                                <div className={styles.suggestionsHeader}>
                                    <FaMagic /> Try Shaadi AI
                                </div>
                                <div className={styles.suggestionGrid}>
                                    <div className={styles.suggestionPill} onClick={() => handleSend("Plan a full wedding in Mumbai for 15 lakhs")}>
                                        <span>💍 Plan Wedding</span>
                                        <p>Plan a full wedding in Mumbai for 15 lakhs</p>
                                    </div>
                                    <div className={styles.suggestionPill} onClick={() => handleSend("Find me a bohemian venue in Delhi")}>
                                        <span>🏰 Bohemian Venue</span>
                                        <p>Find me a bohemian venue in Delhi</p>
                                    </div>
                                    <div className={styles.suggestionPill} onClick={() => handleSend("/personality-quiz")}>
                                        <span>💕 Personality Quiz</span>
                                        <p>Discover your unique wedding style</p>
                                    </div>
                                    <div className={styles.suggestionPill} onClick={() => handleSend("/culture-blender")}>
                                        <span>✨ Culture Blender</span>
                                        <p>Blend two cultures beautifully</p>
                                    </div>
                                    <div className={styles.suggestionPill} onClick={() => handleSend("/conflict-resolver")}>
                                        <span>⚖️ Conflict Resolver</span>
                                        <p>Resolve wedding decisions together</p>
                                    </div>
                                    <div className={styles.suggestionPill} onClick={() => handleSend("/timeline-generator")}>
                                        <span>📅 Timeline Generator</span>
                                        <p>Create your wedding timeline</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        );
    }

    // ======= CHAT VIEW =======
    return (
        <div className={styles.appLayout}>
            {renderSidebar()}
            <div className={styles.mainArea}>
                <div className={styles.chatHeader}>
                    {!sidebarOpen && (
                        <button className={styles.menuBtn} onClick={() => setSidebarOpen(true)}>
                            <FaBars />
                        </button>
                    )}
                    <h2>Shaadi AI</h2>
                </div>

                <div className={styles.chatMessages}>
                    <div className={styles.messagesMaxWidth}>
                        {messages.map((msg, index) => {
                            if (index === 0) return null;

                            return (
                                <div key={index} className={`${styles.messageBlock} ${msg.role === 'user' ? styles.userBlock : styles.aiBlock}`}>
                                    {msg.role === 'ai' && (
                                        <div className={styles.avatar}>
                                            <FaMagic />
                                        </div>
                                    )}
                                    <div className={styles.messageContent}>
                                        {msg.role === 'user' ? (
                                            <div className={styles.userText}>{msg.content}</div>
                                        ) : (
                                            <>
                                                <div className={styles.aiText}>
                                                    {msg.content?.split('\n').map((line, i) => (
                                                        <span key={i}>{line}<br /></span>
                                                    ))}
                                                </div>

                                                {/* Render inline feature forms */}
                                                {msg.featureType === 'personality-quiz' && !msg.featureResult && (
                                                    <PersonalityQuizInline onComplete={(result) => handleFeatureComplete('personality-quiz', result)} />
                                                )}
                                                {msg.featureType === 'culture-blender' && !msg.featureResult && (
                                                    <CultureBlenderInline onComplete={(result) => handleFeatureComplete('culture-blender', result)} />
                                                )}
                                                {msg.featureType === 'conflict-resolver' && !msg.featureResult && (
                                                    <ConflictResolverInline onComplete={(result) => handleFeatureComplete('conflict-resolver', result)} />
                                                )}
                                                {msg.featureType === 'timeline-generator' && !msg.featureResult && (
                                                    <TimelineGeneratorInline onComplete={(result) => handleFeatureComplete('timeline-generator', result)} />
                                                )}

                                                {/* Render feature results */}
                                                {msg.featureResult && msg.featureType === 'personality-quiz' && (
                                                    <PersonalityQuizResult result={msg.featureResult} />
                                                )}
                                                {msg.featureResult && msg.featureType === 'culture-blender' && (
                                                    <CultureBlenderResult result={msg.featureResult} />
                                                )}
                                                {msg.featureResult && msg.featureType === 'conflict-resolver' && (
                                                    <ConflictResolverResult result={msg.featureResult} />
                                                )}
                                                {msg.featureResult && msg.featureType === 'timeline-generator' && (
                                                    <TimelineGeneratorResult result={msg.featureResult} />
                                                )}

                                                {msg.budget_breakdown && Object.keys(msg.budget_breakdown).length > 0 && (
                                                    <div className={styles.budgetBreakdown}>
                                                        <div className={styles.budgetTitle}>
                                                            <FaWallet /> Budget Breakdown
                                                        </div>
                                                        <div className={styles.budgetGrid}>
                                                            {Object.entries(msg.budget_breakdown).map(([cat, amt]) => (
                                                                <div key={cat} className={styles.budgetItem}>
                                                                    <span className={styles.budgetCategory}>{cat}</span>
                                                                    <span className={styles.budgetAmount}>{formatBudget(amt)}</span>
                                                                </div>
                                                            ))}
                                                        </div>
                                                    </div>
                                                )}

                                                {msg.vendors && msg.vendors.length > 0 && (
                                                    <div className={styles.vendorsContainer}>
                                                        {msg.vendors.map((vendor, i) => (
                                                            <div 
                                                                key={i} 
                                                                className={styles.vendorCard}
                                                                onClick={() => {
                                                                    if (vendor.vendor_id) {
                                                                        window.location.href = `/details/info/${vendor.vendor_id}`;
                                                                    }
                                                                }}
                                                                style={{ cursor: vendor.vendor_id ? 'pointer' : 'default' }}
                                                            >
                                                                <div className={styles.vendorHeader}>
                                                                    <h4>{vendor.name}</h4>
                                                                    <span className={styles.vendorCategory}>{vendor.category}</span>
                                                                </div>
                                                                <div className={styles.vendorDetails}>
                                                                    <p><FaMapMarkerAlt /> {vendor.location}</p>
                                                                    <p className={styles.price}>{vendor.price_range}</p>
                                                                </div>
                                                                <div className={styles.vendorWhy}>
                                                                    <FaTags /> <span>{vendor.why_recommended?.join(" • ")}</span>
                                                                </div>
                                                            </div>
                                                        ))}
                                                    </div>
                                                )}

                                                {/* The user's own orders, when they asked about them.
                                                    Only the orders the answer is about appear here —
                                                    showing all of them under a reply about one would
                                                    contradict the text above. */}
                                                {msg.orders && msg.orders.length > 0 && (
                                                    <div className={styles.ordersContainer}>
                                                        {msg.orders.map((order) => (
                                                            <div className={styles.orderCard} key={order.id}>
                                                                <div className={styles.orderTop}>
                                                                    <span className={styles.orderInvoice}>
                                                                        Invoice #{order.invoice}
                                                                    </span>
                                                                    <span
                                                                        className={`${styles.orderStatus} ${
                                                                            styles["orderStatus" + String(order.status).replace(/\s/g, "")] || ""
                                                                        }`}
                                                                    >
                                                                        {order.status}
                                                                    </span>
                                                                </div>
                                                                <ul className={styles.orderItems}>
                                                                    {order.items.map((item, k) => (
                                                                        <li key={item.id || k}>
                                                                            {item.image && (
                                                                                <img src={item.image} alt="" loading="lazy" />
                                                                            )}
                                                                            <span className={styles.orderItemTitle}>
                                                                                {item.title}
                                                                            </span>
                                                                            <span className={styles.orderItemQty}>
                                                                                ×{item.quantity}
                                                                            </span>
                                                                        </li>
                                                                    ))}
                                                                </ul>
                                                                <div className={styles.orderFoot}>
                                                                    <span>{order.itemCount} item{order.itemCount === 1 ? "" : "s"}</span>
                                                                    <strong>₹{Number(order.total).toLocaleString("en-IN")}</strong>
                                                                </div>
                                                            </div>
                                                        ))}
                                                    </div>
                                                )}

                                                {/* Store products. Unlike vendor cards these leave the
                                                    site — the store is a separate app on its own domain,
                                                    so each card is an <a target="_blank"> rather than a
                                                    click handler that pushes a route. */}
                                                {msg.products && msg.products.length > 0 && (
                                                    <div className={styles.productsContainer}>
                                                        {msg.products.map((product, i) => (
                                                            <a
                                                                key={product.id || i}
                                                                className={styles.productCard}
                                                                href={product.url}
                                                                target="_blank"
                                                                rel="noopener noreferrer"
                                                            >
                                                                <div className={styles.productThumb}>
                                                                    {product.image
                                                                        ? <img src={product.image} alt={product.title} loading="lazy" />
                                                                        : <FaTags />}
                                                                    {!product.inStock && (
                                                                        <span className={styles.productSoldOut}>Sold out</span>
                                                                    )}
                                                                </div>
                                                                <div className={styles.productBody}>
                                                                    <span className={styles.productCategory}>{product.category}</span>
                                                                    <h4 className={styles.productTitle}>{product.title}</h4>
                                                                    <div className={styles.productPrice}>
                                                                        <strong>₹{Number(product.price).toLocaleString("en-IN")}</strong>
                                                                        {product.originalPrice > product.price && (
                                                                            <s>₹{Number(product.originalPrice).toLocaleString("en-IN")}</s>
                                                                        )}
                                                                    </div>
                                                                    {/* Why this was picked, when it was picked for a reason
                                                                        specific to this shopper. Only the first — the card is
                                                                        small, and the strongest reason is listed first. */}
                                                                    {product.reasons?.length > 0 && (
                                                                        <span className={styles.productReason}>
                                                                            {product.reasons[0]}
                                                                        </span>
                                                                    )}
                                                                </div>
                                                            </a>
                                                        ))}
                                                    </div>
                                                )}

                                                {msg.comparisons && msg.comparisons.length > 0 && (
                                                    <div className={styles.comparisonsContainer}>
                                                        <div className={styles.budgetTitle}>
                                                            <FaMagic /> Auto-Comparison
                                                        </div>
                                                        {msg.comparisons.map((comp, i) => (
                                                            <div key={i} className={styles.comparisonCard}>
                                                                <div className={styles.comparisonGrid}>
                                                                    <div className={styles.compCol}>
                                                                        <h4>{comp.vendor_1.name}</h4>
                                                                        <p><strong>Price:</strong> {comp.vendor_1.price}</p>
                                                                        <p><strong>Capacity:</strong> {comp.vendor_1.capacity}</p>
                                                                        <p><strong>Setup:</strong> {comp.vendor_1.indoor_outdoor}</p>
                                                                    </div>
                                                                    <div className={styles.compVs}>VS</div>
                                                                    <div className={styles.compCol}>
                                                                        <h4>{comp.vendor_2.name}</h4>
                                                                        <p><strong>Price:</strong> {comp.vendor_2.price}</p>
                                                                        <p><strong>Capacity:</strong> {comp.vendor_2.capacity}</p>
                                                                        <p><strong>Setup:</strong> {comp.vendor_2.indoor_outdoor}</p>
                                                                    </div>
                                                                </div>
                                                                <div className={styles.compRecommendation}>
                                                                    💡 {comp.recommendation}
                                                                </div>
                                                            </div>
                                                        ))}
                                                    </div>
                                                )}

                                                {msg.suggestions && msg.suggestions.length > 0 && (
                                                    <div className={styles.suggestionsContainer}>
                                                        {msg.suggestions.map((sug, i) => (
                                                            <div key={i} className={styles.suggestionAlert}>
                                                                ✨ {sug}
                                                            </div>
                                                        ))}
                                                    </div>
                                                )}
                                            </>
                                        )}
                                    </div>
                                </div>
                            )
                        })}

                        {loading && (
                            <div className={`${styles.messageBlock} ${styles.aiBlock}`}>
                                <div className={styles.avatar}><FaMagic /></div>
                                <div className={styles.loadingBubble}>
                                    <div className={styles.dotPulse}></div>
                                </div>
                            </div>
                        )}
                        <div ref={chatEndRef} className={styles.chatEndMarker} />
                    </div>
                </div>

                <div className={styles.chatInputWrapper}>
                    <div className={styles.chatInputMaxWidth}>
                        {renderInputArea()}
                    </div>
                </div>
            </div>
        </div>
    );
};

export default ShaadiAI;